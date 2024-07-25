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
    // TODO: Check that is the case... :)
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
        let otherAccountsDescriptor = FetchDescriptor<PublicKeyMetadata>()
        if let otherAccounts = try? modelContainer?.mainContext.fetch(otherAccountsDescriptor) {
            
            for otherAccount in otherAccounts {
                pubkeys.insert(otherAccount.publicKey)
            }
            
            // sort pubkeys
            // This should keep subscription additions from always
            // happening since its a no op if the Subscription is equal to current
            // subscription
            // TODO: Check that is the case... :)
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
                            .custom(10002),
                        ])
                    ], id: "owner-metadata")
                ])
                nostrClient.connect(relayWithUrl: relay.url)
            }
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
                            Kind.custom(39000)
                        ])
                    ], id: "group-list")
                ])
            }
            self.selectedRelay = relays.first // TODO: Need better selection here...
        }
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    // TODO: Check that is the case... :)
    // TODO: Also we should add since filter based on last message already stored
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) {
        let descriptor = FetchDescriptor<SimpleGroup>()
        if let groups = try? modelContainer?.mainContext.fetch(descriptor) {
            let groupIds = groups.map({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.custom(9)
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
            let modelContext = self.backgroundContext()
            try? modelContext?.delete(model: SimpleGroup.self, where: #Predicate { $0.relayUrl == relayUrl })
            try? modelContext?.delete(model: EventMessage.self, where: #Predicate { $0.relayUrl == relayUrl })
            try? modelContext?.save()
        }
    }
    
    @MainActor
    func updateRelayInformationForAll() async -> Void {
        Task.detached {
            let relaysDescriptor = FetchDescriptor<Relay>()
            let modelContext = self.backgroundContext()
            if let relays = try? modelContext?.fetch(relaysDescriptor) {
                await withTaskGroup(of: Void.self) { group in
                    for relay in relays {
                        group.addTask {
                            await relay.updateRelayInfo()
                        }
                    }
                    try? modelContext?.save()
                }
            }
        }
    }
    
    func backgroundContext() -> ModelContext? {
        if let modelContainer {
            return ModelContext(modelContainer)
        }
        return nil
    }
    
    func backgroundGetPublicKeyMetadata(forPublicKey publicKey: String, modelContext: ModelContext?) async -> PublicKeyMetadata? {
        let desc = FetchDescriptor<PublicKeyMetadata>(predicate: #Predicate<PublicKeyMetadata>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    func backgroundGetOwnerAccount(forPublicKey publicKey: String, modelContext: ModelContext?) async -> OwnerAccount? {
        let desc = FetchDescriptor<OwnerAccount>(predicate: #Predicate<OwnerAccount>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    func processMetadata(event: Event, relayUrl: String, subscriptionId: String) {
        Task.detached {
            let modelContext = self.backgroundContext()
            if let ownerAccount = await self.backgroundGetOwnerAccount(forPublicKey: event.pubkey, modelContext: modelContext) {
                if ownerAccount.publicKeyMetadata == nil {
                    ownerAccount.publicKeyMetadata = PublicKeyMetadata.create(from: event)
                    try? modelContext?.save()
                }
            } else if let publickeyMetadata = PublicKeyMetadata.create(from: event) {
                modelContext?.insert(publickeyMetadata)
                try? modelContext?.save()
            }
        }
    }
    
//    func processOwnerAccountListData(event: Event, relayUrl: String, subscriptionId: String) {
//        Task.detached {
//            let modelContext = self.backgroundContext()
//            if let ownerAccount = await self.backgroundGetOwnerAccount(forPublicKey: event.pubkey, modelContext: modelContext) {
//                let tags = event.tags.map({ $0 })
//                let rtags = tags.filter({ $0.id == "r" })
//                if rtags.count > 0 {
//                    if let currentMetadataRelays = await self.backgroundGetMetadataRelays(modelContext: modelContext) {
//                        let relays = tags.compactMap({ $0.otherInformation.first?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }) // TODO: Validate url
//                        for relay in relays {
//                            ownerAccount.metadataRelayIds.insert(relay)
//                            if !currentMetadataRelays.contains(where: { $0.url == relay }) {
//                                if let nr = Relay.createNew(withUrl: relay) {
//                                    nr.metadataOnly = true
//                                    modelContext?.insert(nr)
//                                }
//                            }
//                        }
//                        try? modelContext?.save()
////                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////                            self.tryBootstrapingOwnerAccountMetadataRelays()
////                        }
//                    }
//                }
//            }
//        }
//    }
    
    func processChatGroupData(event: Event, relayUrl: String, subscriptionId: String) {
        Task.detached {
            if let simpleGroup = SimpleGroup.create(from: event, relayUrl: relayUrl) {
                let modelContext = self.backgroundContext()
                modelContext?.insert(simpleGroup)
                try? modelContext?.save()
            }
        }
    }
    
    func processChatMessageData(event: Event, relayUrl: String, subscriptionId: String) {
        Task.detached {
            if let eventMessage = EventMessage.create(from: event, relayUrl: relayUrl) {
                let modelContext = self.backgroundContext()
                modelContext?.insert(eventMessage)
                try? modelContext?.save()
            }
        }
    }
}

extension AppState: NostrClientDelegate {
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
        case .event(let id, let event):
            if event.isValid() {
                switch event.kind {
                    case Kind.setMetadata:
                        processMetadata(event: event, relayUrl: relayUrl, subscriptionId: id)
                    case Kind.custom(39000):
                        processChatGroupData(event: event, relayUrl: relayUrl, subscriptionId: id)
                    case Kind.custom(9):
                        processChatMessageData(event: event, relayUrl: relayUrl, subscriptionId: id)
                    case Kind.custom(10009): ()
                    case Kind.custom(10002): ()
                        //processOwnerAccountListData(event: event, relayUrl: relayUrl, subscriptionId: id)
                    default:
                        print(event.kind)
                }
            } else {
                print("\(event.id ?? "") is invalid")
            }
        case .notice(let notice):
            print(notice)
        case .ok(let id, let acceptance, let m):
            print(id, acceptance, message)
        case .eose(let id):
            print("EOSE => Subscription: \(id), relay: \(relayUrl)")
                if id == "group-list" {
                    Task {
                        await subscribeGroups(withRelayUrl: relayUrl)
                    }
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
