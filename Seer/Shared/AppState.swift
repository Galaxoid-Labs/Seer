//
//  AppState.swift
//  Seer
//
//  Created by Jacob Davis on 4/8/24.
//

import Foundation
import SwiftUI
import SwiftData
import KeychainAccess
import NostrClient
import Nostr

class AppState: ObservableObject {
    
    var modelContainer: ModelContainer?
    var nostrClient = NostrClient()
    
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?
    var checkBusyTimer: Timer?

    static let shared = AppState()
    
    @Published var showOnboarding = false
    @Published var selectedRelay: Relay?
    
    private init() {
        nostrClient.delegate = self
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func connectAllMetadataRelays() {
        
        // Metadata relays
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 })
        guard let relays = try? modelContainer?.mainContext.fetch(relaysDescriptor) else { return }
        
        // Get selected owner pubkey
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        guard let selectedAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first else { return }
        
        var pubkeys = Set([selectedAccount.publicKey])
        
        // Get other pubkeys
        let otherAccountsDescriptor = FetchDescriptor<DBEvent>(predicate: #Predicate<DBEvent> { $0.kind == kindSetMetdata || $0.kind == kindGroupChatMessage })
        if let otherAccounts = try? modelContainer?.mainContext.fetch(otherAccountsDescriptor) {
            for otherAccount in otherAccounts {
                pubkeys.insert(otherAccount.pubkey)
            }
        }
        
        // sort pubkeys
        // This should keep subscription additions from always
        // happening since its a no op if the Subscription is equal to current
        // subscription
        let sortedPubkeys = Array(pubkeys).sorted()
        
        for relay in relays {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                Subscription(filters: [
                    Filter(authors: sortedPubkeys, kinds: [
                        .setMetadata,
                    ])
                ], id: "public-metadata"),
                Subscription(filters: [
                    Filter(authors: [selectedAccount.publicKey], kinds: [
                        .groupList,
                    ])
                ], id: "owner-metadata")
            ])
            nostrClient.connect(relayWithUrl: relay.url)
        }
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    // TODO: Check that is the case... :)
    @MainActor func connectAllNip29Relays() {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
            for relay in relays {
                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMetadata
                        ])
                    ], id: "group-list"),
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMembers
                        ])
                    ], id: "group-members")
                ])
            }
            self.selectedRelay = relays.first // TODO: Need better selection here...
        }
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) {
        let descriptor = FetchDescriptor<DBEvent>(predicate: #Predicate<DBEvent> { $0.kind == kindGroupMetadata && $0.relayUrl == relayUrl })
        if let groups = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // TODO: Get oldest message and use until filter so we don't keep getting the same shit
            
            let groupIds = groups.compactMap({ GroupVM(event: $0)?.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupChatMessage,
                    Kind.groupChatMessageReply,
                    Kind.groupForumMessage,
                    Kind.groupForumMessageReply
                ], tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: "chat-messages")
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
    }
    
    public func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
    }
    
    @MainActor
    func removeDataFor(relayUrl: String) async -> Void {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.kind == kindGroupMetadata && $0.relayUrl == relayUrl })
            try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.kind == kindGroupChatMessage && $0.relayUrl == relayUrl })
            try? modelContext.save()
        }
    }
    
    @MainActor
    func updateRelayInformationForAll() async -> Void {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            guard let relays = try? modelContext.fetch(FetchDescriptor<Relay>()) else { return }
            await withTaskGroup(of: Void.self) { group in
                for relay in relays {
                    group.addTask {
                        await relay.updateRelayInfo()
                    }
                }
                try? modelContext.save()
            }
        }
    }
    
    func backgroundContext() -> ModelContext? {
        guard let modelContainer else { return nil }
        return ModelContext(modelContainer)
    }
    
    func getOwnerAccount(forPublicKey publicKey: String, modelContext: ModelContext?) async -> OwnerAccount? {
        let desc = FetchDescriptor<OwnerAccount>(predicate: #Predicate<OwnerAccount>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    func processDBEvent(event: Event, relayUrl: String) {
        Task.detached {
            guard let dbEvent = DBEvent(event: event, relayUrl: relayUrl) else { return }
            guard let modelContext = self.backgroundContext() else { return }
            
//            let kind = Int(event.kind.id)
//            let kindPredicate = #Predicate<DBEvent> { $0.kind == kind }
//            let pubkeyPredicate = #Predicate<DBEvent> { $0.pubkey == event.pubkey }
           
            // Since replacable events have diffrent Id's
            // We need to delete current version if it's there
            // before inserting. Anything else with same Id
            // will simply be overwritten
//            switch event.kind {
//                case Kind.setMetadata:
//                    let combinedPredicate = #Predicate<DBEvent> { kindPredicate.evaluate($0) && pubkeyPredicate.evaluate($0) }
//                    try? modelContext.delete(model: DBEvent.self, where: combinedPredicate)
//                    try? modelContext.save()
//                default: ()
//
//            }
            modelContext.insert(dbEvent)
            try? modelContext.save()
        }
    }
    
}

extension AppState: NostrClientDelegate {
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
        case .event(_, let event):
            if event.isValid() {
                processDBEvent(event: event, relayUrl: relayUrl)
            } else {
                print("\(event.id ?? "") is an invalid event on \(relayUrl)")
            }
        case .notice(let notice):
            print(notice)
        case .ok(let id, let acceptance, let m):
            print(id, acceptance, m)
        case .eose(let id):
            print("EOSE => Subscription: \(id), relay: \(relayUrl)")
            if id == "group-list" {
                Task {
                    await subscribeGroups(withRelayUrl: relayUrl)
                }
            }
            if id == "chat-messages" {
                // TODO: Create publickeymetadata for the event message pubkeys..
            }
        case .closed(let id, let message):
            print(id, message)
        case .other(let other):
            print(other)
        case .auth(let challenge):
            print("Auth: \(challenge)")
        }
    }
    
}
