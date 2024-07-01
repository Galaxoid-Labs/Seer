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
    
    @Published var showWelcome = false
    @Published var selectedRelay: Relay?
    
    private init() {
        nostrClient.delegate = self
    }
    
    @MainActor func tryBootstrapingOwnerAccountMetadataRelays() {
//        let accountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
//        if let account = try? modelContainer?.mainContext.fetch(accountDescriptor).first {
//            
//            let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.metadataOnly })
//            if let relays = try? modelContainer?.mainContext.fetch(relaysDescriptor) {
//                if relays.isEmpty {
//                    let r = Relay(url: "wss://user.kindpag.es", metadataOnly: true)
//                    modelContainer?.mainContext.insert(r)
//                    tryBootstrapingOwnerAccountMetadataRelays()
//                } else {
//                    
//                    for relay in relays {
//                        nostrClient.add(relayWithUrl: relay.url, subscriptions: [
//                            Subscription(filters: [
//                                EventFilter(authors: [account.publicKey], eventKinds: [
//                                    .setMetadata, .custom(10002)
//                                ])
//                            ], id: "owner-metadata")
//                        ])
//                        nostrClient.connect(relayWithUrl: relay.url)
//                    }
//                    
//                }
//            }
//            
//        }
//        
//        Task {
//            await updateRelayInformationForAll()
//        }
//        
    }
    
    
    
    @MainActor func connectAllNip29Relays() {
        let descriptor = FetchDescriptor<Relay>()
        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
            for relay in relays {
                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
//                    Subscription(filters: [
//                        EventFilter(eventKinds: [
//                            EventKind.custom(9)
//                        ], tags: [Tag(id: "h", otherInformation: "82a67966", "10b37966")]),
//                    ], id: "chat-messages"),
//                    Subscription(filters: [
//                        EventFilter(authors: ["c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778"], eventKinds: [
//                            EventKind.custom(10009)
//                        ]),
//                    ], id: "group-list"),
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.custom(39000)
                        ])
                    ], id: "group-list")
                ])
            }
            self.selectedRelay = relays.first
        }
    }
    
//    @MainActor func subscribeAllGroups() {
//        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.metadataOnly == false })
//        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
//            for relay in relays {
//                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
////                    Subscription(filters: [
////                        EventFilter(eventKinds: [
////                            EventKind.custom(9)
////                        ], tags: [Tag(id: "h", otherInformation: "82a67966", "10b37966")]),
////                    ], id: "chat-messages"),
////                    Subscription(filters: [
////                        EventFilter(authors: ["c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778"], eventKinds: [
////                            EventKind.custom(10009)
////                        ]),
////                    ], id: "group-list"),
//                    Subscription(filters: [
//                        EventFilter(eventKinds: [
//                            EventKind.custom(39000)
//                        ])
//                    ], id: "group-list")
//                ])
//            }
//            self.selectedRelay = relays.first
//        }
//    }
    
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) {
        let descriptor = FetchDescriptor<SimpleGroup>()
        if let groups = try? modelContainer?.mainContext.fetch(descriptor) {
            let groupIds = groups.map({ $0.id })
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
    
    func backgroundGetMetadataRelays(modelContext: ModelContext?) async -> [Relay]? {
        let desc = FetchDescriptor<Relay>(predicate: #Predicate { $0.metadataOnly })
        return try? modelContext?.fetch(desc)
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
            }
        }
    }
    
    func processOwnerAccountListData(event: Event, relayUrl: String, subscriptionId: String) {
        Task.detached {
            let modelContext = self.backgroundContext()
            if let ownerAccount = await self.backgroundGetOwnerAccount(forPublicKey: event.pubkey, modelContext: modelContext) {
                let tags = event.tags.map({ $0 })
                let rtags = tags.filter({ $0.id == "r" })
                if rtags.count > 0 {
                    if let currentMetadataRelays = await self.backgroundGetMetadataRelays(modelContext: modelContext) {
                        let relays = tags.compactMap({ $0.otherInformation.first?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }) // TODO: Validate url
                        for relay in relays {
                            ownerAccount.metadataRelayIds.insert(relay)
                            if !currentMetadataRelays.contains(where: { $0.url == relay }) {
                                if let nr = Relay.createNew(withUrl: relay) {
                                    nr.metadataOnly = true
                                    modelContext?.insert(nr)
                                }
                            }
                        }
                        try? modelContext?.save()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.tryBootstrapingOwnerAccountMetadataRelays()
                        }
                    }
                }
            }
        }
    }
    
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
                    case Kind.custom(10002):
                        processOwnerAccountListData(event: event, relayUrl: relayUrl, subscriptionId: id)
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
