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

let IdSubChatMessages = "IdSubChatMessages"
let IdSubPublicMetadata = "IdPublicMetadata"
let IdSubOwnerMetadata = "IdOwnerMetadata"
let IdSubGroupList = "IdGroupList"
let IdSubGroupMembers = "IdSubGroupMembers"

class AppState: ObservableObject {
    
    var modelContainer: ModelContainer?
    var nostrClient = NostrClient()
    
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?
    var checkBusyTimer: Timer?

    static let shared = AppState()
    
    @Published var showOnboarding = false
    @Published var selectedRelay: Relay?
    @State private var statuses: [String: Bool] = [:]
    var relayConnectionStatus: [String: Binding<Bool>] {
        Dictionary(uniqueKeysWithValues: statuses.map { key, value in
            (key, Binding(
                get: { self.statuses[key, default: false] },
                set: { self.statuses[key] = $0 }
            ))
        })
    }
    
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
        // TODO: Maybe just get pubkeys from groupMember, groupAdmins events?
        let otherAccountsDescriptor = FetchDescriptor<DBEvent>(predicate: #Predicate<DBEvent> { $0.kind == kindSetMetdata || $0.kind == kindGroupChatMessage })
        if let otherAccounts = try? modelContainer?.mainContext.fetch(otherAccountsDescriptor) {
            for otherAccount in otherAccounts {
                pubkeys.insert(otherAccount.pubkey)
            }
        }
        
        let membersDescriptor = FetchDescriptor<DBEvent>(predicate: #Predicate<DBEvent> { $0.kind == kindGroupMembers || $0.kind == kindGroupAdmins })
        if let otherAccounts = try? modelContainer?.mainContext.fetch(membersDescriptor) {
            let members = otherAccounts.map({ $0.tags.filter({ $0.id == "p" })
                .compactMap({ $0.otherInformation.last }) })
                .reduce([], +).filter({ $0.isValidPublicKey })
            for member in members {
                pubkeys.insert(member)
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
                ], id: IdSubPublicMetadata),
                Subscription(filters: [
                    Filter(authors: [selectedAccount.publicKey], kinds: [
                        .setMetadata,
                    ])
                ], id: IdSubOwnerMetadata)
            ])
            nostrClient.connect(relayWithUrl: relay.url)
        }
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func connectAllNip29Relays() {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
            for relay in relays {
                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMetadata
                        ])
                    ], id: IdSubGroupList),
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMembers,
                            Kind.groupAdmins
                        ])
                    ], id: IdSubGroupMembers)
                ])
            }
            self.selectedRelay = relays.first // TODO: Need better selection here...
        }
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) {
        
        let kindsPredicate = #Predicate<DBEvent> { $0.kind == kindGroupMetadata
            || $0.kind == kindGroupChatMessage || $0.kind == kindGroupChatMessageReply
            || $0.kind == kindGroupForumMessage || $0.kind == kindGroupForumMessageReply }
        let relayPredicate = #Predicate<DBEvent> { $0.relayUrl == relayUrl }
        
        let descriptor = FetchDescriptor<DBEvent>(predicate: #Predicate<DBEvent> { kindsPredicate.evaluate($0) && relayPredicate.evaluate($0) })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            let since = events.min(by: { $0.createdAt > $1.createdAt })
            let groupIds = events.filter({ $0.kind == kindGroupMetadata }).compactMap({ GroupVM(event: $0)?.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupChatMessage,
                    //Kind.groupChatMessageReply,
                    Kind.groupForumMessage,
                    //Kind.groupForumMessageReply
                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubChatMessages)
            
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
            try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.relayUrl == relayUrl })
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
            
            let kind = Int(event.kind.id)
            let kindPredicate = #Predicate<DBEvent> { $0.kind == kind }
            let pubkeyPredicate = #Predicate<DBEvent> { $0.pubkey == event.pubkey }
            let relayPredicate = #Predicate<DBEvent> { $0.relayUrl == relayUrl }

            // Since replacable events have diffrent Id's
            // We need to delete current version if it's there
            // before inserting. Anything else with same Id
            // will simply be overwritten
            switch event.kind {
                case Kind.setMetadata:
                    let combinedPredicate = #Predicate<DBEvent> { kindPredicate.evaluate($0) && pubkeyPredicate.evaluate($0) }
                    try? modelContext.delete(model: DBEvent.self, where: combinedPredicate)
                    try? modelContext.save()
                case Kind.groupMetadata, Kind.groupMembers, Kind.groupAdmins:
                    let tags = event.tags.map({ $0 })
                    guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return }
                    let searchGroupId = "d\(DBEvent.infoDelimiter)\(groupId)"
                    let groupPredicate = #Predicate<DBEvent> { $0.serializedTags.contains(searchGroupId) }
                    let combinedPredicate = #Predicate<DBEvent> { kindPredicate.evaluate($0) && pubkeyPredicate.evaluate($0) && relayPredicate.evaluate($0) && groupPredicate.evaluate($0) }
                    try? modelContext.delete(model: DBEvent.self, where: combinedPredicate)
                    try? modelContext.save()
                default: ()

            }
            
            modelContext.insert(dbEvent)
            try? modelContext.save()
        }
    }
    
    func joinGroup(ownerAccount: OwnerAccount, group: GroupVM) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
                              kind: .groupJoinRequest, tags: [Tag(id: "h", otherInformation: groupId)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    func addMember(ownerAccount: OwnerAccount, group: GroupVM, publicKey: String) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupAddUser,
                              tags: [Tag(id: "h", otherInformation: groupId), Tag(id: "p", otherInformation: publicKey)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    func removeMember(ownerAccount: OwnerAccount, group: GroupVM, publicKey: String) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupRemoveUser,
                              tags: [Tag(id: "h", otherInformation: groupId), Tag(id: "p", otherInformation: publicKey)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    func sendChatMessage(ownerAccount: OwnerAccount, group: GroupVM, withText text: String) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
    
        var event = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
                          tags: [Tag(id: "h", otherInformation: groupId)], content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
//        if let clientMessage = try? ClientMessage.event(event).string() {
//           print(clientMessage)
//        }
        
        nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
    }
    
    func sendChatMessageReply(ownerAccount: OwnerAccount, group: GroupVM, withText text: String, replyChatMessage: ChatMessageVM) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var tags: [Tag] = [Tag(id: "h", otherInformation: groupId)]
        if let rootEventId = replyChatMessage.rootEventId {
            tags.append(Tag(id: "e", otherInformation: [rootEventId, relayUrl, "root", replyChatMessage.publicKey]))
            tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
        } else {
            tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "root", replyChatMessage.publicKey]))
            tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
        }
        
        var event = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
                          tags: tags, content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
    }
    
    #if os(macOS)
    func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
    #else
    func copyToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }
    #endif
    
}

extension AppState: NostrClientDelegate {
    func didConnect(relayUrl: String) {
        statuses[relayUrl] = true
        relayConnectionStatus[relayUrl]?.wrappedValue = true
    }
    
    func didDisconnect(relayUrl: String) {
        statuses[relayUrl] = false
        relayConnectionStatus[relayUrl]?.wrappedValue = false
    }
    
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
            switch id {
                case IdSubGroupList:
                    Task {
                        await subscribeGroups(withRelayUrl: relayUrl)
                    }
                case IdSubChatMessages,IdSubGroupList:
                    Task {
                        await connectAllMetadataRelays()
                    }
                default:
                    ()
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
