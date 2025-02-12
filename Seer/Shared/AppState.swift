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
let IdSubGroupAdmins = "IdSubGroupAdmins"
let IdSubOwnerGroupMembership = "IdOwnerGroupMembership"

class AppState: ObservableObject {
    
    var modelContainer: ModelContainer?
    var nostrClient = NostrClient()
    
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?
    var checkBusyTimer: Timer?

    static let shared = AppState()
    
    @Published var showOnboarding = false
    @Published var selectedOwnerAccount: OwnerAccount?
    @Published var selectedRelay: Relay?
    @Published var selectedGroup: Group? {
        didSet {
            chatMessageNumResults = 50
        }
    }
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    private init() {
        nostrClient.delegate = self
    }
    
    @MainActor func initialSetup() async {
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        self.selectedOwnerAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first
    }
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func connectAllMetadataRelays() async {
        
        // Metadata relays
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 })
        guard let relays = try? modelContainer?.mainContext.fetch(relaysDescriptor) else { return }
        
        // Get selected owner pubkey
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        guard let selectedAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first else { return }
        
        var pubkeys = Set([selectedAccount.publicKey])
        
        let membersDescriptor = FetchDescriptor<GroupMember>()
        if let members = try? modelContainer?.mainContext.fetch(membersDescriptor) {
            for member in members {
                pubkeys.insert(member.publicKey)
            }
        }
        
        let adminsDescriptor = FetchDescriptor<GroupAdmin>()
        if let admins = try? modelContainer?.mainContext.fetch(adminsDescriptor) {
            for admin in admins {
                pubkeys.insert(admin.publicKey)
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
    @MainActor func connectAllNip29Relays() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
            for relay in relays {
                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMetadata
                        ])
                    ], id: IdSubGroupList)
                ])
            }
            self.selectedRelay = relays.first // TODO: Need better selection here...
        }
    }
    
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<Group>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
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
    
    @MainActor func subscribeOwnerGroupMembership(withRelayUrl relayUrl: String) async {
        
        // Get selected owner pubkey
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        guard let selectedAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first else { return }
        
        let descriptor = FetchDescriptor<Group>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAddUser,
                    Kind.groupRemoveUser
                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds),
                                      Tag(id: "p", otherInformation: [selectedAccount.publicKey])]),
            ], id: IdSubOwnerGroupMembership)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
    }
    
    @MainActor func subscribeGroupMemberships(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<Group>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAddUser,
                    Kind.groupRemoveUser
                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubGroupMembers)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
    }
    
    @MainActor func subscribeGroupAdmins(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<Group>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAdmins
                ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
            ], id: IdSubGroupAdmins)
            
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
            //try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.relayUrl == relayUrl })
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
    
    func getModels<T: PersistentModel>(context: ModelContext, modelType: T.Type, predicate: Predicate<T>) -> [T]? {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try? context.fetch(descriptor)
    }
    
    func getOwnerAccount(forPublicKey publicKey: String, modelContext: ModelContext?) async -> OwnerAccount? {
        let desc = FetchDescriptor<OwnerAccount>(predicate: #Predicate<OwnerAccount>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    func process(event: Event, relayUrl: String) {
        Task.detached {
            
            guard let eventId = event.id else { return }
            let publicKey = event.pubkey
            
            guard let modelContext = self.backgroundContext() else { return }
            switch event.kind {
                case Kind.setMetadata:
                    
                    if let publicKeyMetadata = PublicKeyMetadata(event: event) {
                        modelContext.insert(publicKeyMetadata)
                        
                        //try? modelContext.save()
                        
                        // Fetch all ChatMessages with publicKey and assign publicKeyMetadata relationship
                        if let messages = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                         predicate: #Predicate<ChatMessage> { $0.publicKey == publicKey }) {
                            for message in messages {
                                message.publicKeyMetadata = publicKeyMetadata
                            }
                        }
                        
                        try? modelContext.save()

                    }
                    
                case Kind.groupMetadata:
                    
                    if let group = Group(event: event, relayUrl: relayUrl) {
                        let groupId = group.id
                        modelContext.insert(group)
                        
                        //try? modelContext.save()
                        
                        if let selectedOwnerAccount = self.selectedOwnerAccount {
                            
                            let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
                            
                            group.isMember = self.getModels(context: modelContext, modelType: GroupMember.self,
                                                            predicate: #Predicate<GroupMember> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId && $0.relayUrl == relayUrl })?.first != nil
                            
                            group.isAdmin = self.getModels(context: modelContext, modelType: GroupAdmin.self,
                                                           predicate: #Predicate<GroupAdmin> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId  && $0.relayUrl == relayUrl })?.first != nil
                            
                        }
                        
                        try? modelContext.save()
                        
                    }
                    
//                case Kind.groupMembers:
//                    
//                    let tags = event.tags.map({ $0 })
//                    if let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first {
//                        let members = tags.filter({ $0.id == "p" })
//                            .compactMap({ $0.otherInformation.last })
//                            .filter({ $0.isValidPublicKey })
//                            .map({ GroupMember(publicKey: $0, groupId: groupId, relayUrl: relayUrl) })
//                        
//                        for member in members {
//                            modelContext.insert(member)
//                        }
//                        
//                        //try? modelContext.save()
//                        
//                        let publicKeys = members.map({ $0.publicKey })
//                        if let publicKeyMetadatas = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
//                                                                   predicate: #Predicate<PublicKeyMetadata> { publicKeys.contains($0.publicKey) }) {
//                            for member in members {
//                                member.publicKeyMetadata = publicKeyMetadatas.first(where: { $0.publicKey == member.publicKey })
//                            }
//                        }
//                        
//                        // Set group isAdmin/isMember just incase we got the members/admins after the group was fetched
//                        if let groups = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate { $0.relayUrl == relayUrl && $0.id == groupId }) {
//                            if let selectedOwnerAccount = self.selectedOwnerAccount {
//                                let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
//                                for group in groups {
//                                    group.isMember = members.first(where: { $0.publicKey == selectedOwnerPublicKey }) != nil
//                                }
//                            }
//                        }
//                        
//                        try? modelContext.save()
//                    }
                    
                case Kind.groupAdmins:
                    
                    let tags = event.tags.map({ $0 })
                    if let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first {
                        let admins = tags.filter({ $0.id == "p" })
                            .compactMap({ $0.otherInformation })
                            .compactMap({ GroupAdmin(publicKey: $0.first, groupId: groupId, capabilities: Array($0[2...]),
                                                     relayUrl: relayUrl) })
                            .filter({ $0.publicKey.isValidPublicKey })
                        
                        for admin in admins {
                            modelContext.insert(admin)
                        }
                        
                        let publicKeys = admins.map({ $0.publicKey })
                        if let publicKeyMetadatas = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
                                                                   predicate: #Predicate<PublicKeyMetadata> { publicKeys.contains($0.publicKey) }) {
                            for admin in admins {
                                admin.publicKeyMetadata = publicKeyMetadatas.first(where: { $0.publicKey == admin.publicKey })
                            }
                        }
                        
                        if let groups = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate { $0.relayUrl == relayUrl && $0.id == groupId }) {
                            if let selectedOwnerAccount = self.selectedOwnerAccount {
                                let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
                                for group in groups {
                                    group.isAdmin = admins.first(where: { $0.publicKey == selectedOwnerPublicKey }) != nil
                                }
                            }
                        }
                        
                        try? modelContext.save()
                    }
                    
                case Kind.groupChatMessage:
                    
                    if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
                        
                        if let chatMessages = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                             predicate: #Predicate<ChatMessage> { $0.id == eventId }), chatMessages.count == 0 {
                            
                            modelContext.insert(chatMessage)
                            
                            //try? modelContext.save()
                            
                            if let publicKeyMetadata = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
                                                                      predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })?.first {
                                chatMessage.publicKeyMetadata = publicKeyMetadata
                            }
                            
                            if let replyToEventId = chatMessage.replyToEventId {
                                if let replyToChatMessage = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                                        predicate: #Predicate<ChatMessage> { $0.id == replyToEventId })?.first {
                                    chatMessage.replyToChatMessage = replyToChatMessage
                                }
                            }
                            
                            // Check if any messages point to me?
                            if let replies = self.getModels(context: modelContext, modelType: ChatMessage.self, predicate: #Predicate<ChatMessage> { $0.replyToEventId == eventId }) {
                                
                                for message in replies {
                                    message.replyToChatMessage = chatMessage
                                }
                                
                            }
                            
                            try? modelContext.save()
                            
                        }
                    }
                    
                case Kind.groupAddUser:
                    let tags = event.tags.map({ $0 })
                    guard let groupId = tags.first(where: { $0.id == "h" })?.otherInformation.first else { return }
                    guard let pubkey = tags.first(where: { $0.id == "p" })?.otherInformation.first else { return }
                    
                    // grab memeber from db
                    if let member = self.getModels(context: modelContext, modelType: GroupMember.self, predicate: #Predicate<GroupMember> { $0.groupId == groupId && $0.publicKey == pubkey })?.first {
                       
                        // determine if we have a removal or added
                        let isRemoval: Bool = member.removedAt != nil
                        guard let date = member.removedAt ?? member.addedAt else { return }
                        
                        // check if event date is newer than what we have
                        if event.createdAt.date > date {
                            if isRemoval {
                                member.removedAt = nil
                            }
                            member.addedAt = event.createdAt.date
                        }
                        
                        if let group = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate<Group> { $0.id == groupId })?.first {
                            group.isMember = true
                        }
                        
                        try? modelContext.save()
                        
                    } else {
                        let member = GroupMember(publicKey: pubkey, groupId: groupId, relayUrl: relayUrl)
                        member.addedAt = event.createdAt.date
                        modelContext.insert(member)
                        
                        if let group = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate<Group> { $0.id == groupId })?.first {
                            group.isMember = true
                        }
                        
                        try? modelContext.save()
                    }
                    
                case Kind.groupRemoveUser:
                    let tags = event.tags.map({ $0 })
                    guard let groupId = tags.first(where: { $0.id == "h" })?.otherInformation.first else { return }
                    guard let pubkey = tags.first(where: { $0.id == "p" })?.otherInformation.first else { return }
                    
                    // grab memeber from db
                    if let member = self.getModels(context: modelContext, modelType: GroupMember.self, predicate: #Predicate<GroupMember> { $0.groupId == groupId && $0.publicKey == pubkey })?.first {
                       
                        // determine if we have a removal or added
                        let isRemoval: Bool = member.removedAt != nil
                        guard let date = member.removedAt ?? member.addedAt else { return }
                        
                        // check if event date is newer than what we have
                        if event.createdAt.date > date {
                            if !isRemoval {
                                member.addedAt = nil
                            }
                            member.removedAt = event.createdAt.date
                        }
                        
                        if let group = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate<Group> { $0.id == groupId })?.first {
                            group.isMember = false
                        }
                        
                        try? modelContext.save()
                        
                    } else {
                        let member = GroupMember(publicKey: pubkey, groupId: groupId, relayUrl: relayUrl)
                        member.removedAt = event.createdAt.date
                        modelContext.insert(member)
                        
                        if let group = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate<Group> { $0.id == groupId })?.first {
                            group.isMember = false
                        }
                        
                        try? modelContext.save()
                    }
                    
                default: ()
            }
        }
    }
    
    func editGroup(ownerAccount: OwnerAccount, group: Group) {
        guard let key = ownerAccount.getKeyPair() else { return }
        guard let selectedRelay else { return }
        let groupId = group.id
        var editGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
                                   kind: .groupEditMetadata, tags:
                                    [Tag(id: "h", otherInformation: groupId),
                                     Tag(underlyingData: ["name", "Cool Group"]),
                                     Tag(underlyingData: ["about", "This is a cool group"]),
                                     Tag(underlyingData: ["picture", "https://img.freepik.com/premium-vector/friendly-monkey-avatar_706143-7913.jpg"]),
                                     Tag(underlyingData: ["closed"])
                                    ]
                                   , content: "")
        do {
            try editGroupEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: editGroupEvent, onlyToRelayUrls: [selectedRelay.url])
    }
    
    func createGroup(ownerAccount: OwnerAccount) {
        guard let key = ownerAccount.getKeyPair() else { return }
        guard let selectedRelay else { return }
        let groupId = "testgroup"
        //var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
         //                         kind: .groupCreate, tags: [Tag(id: "h", otherInformation: groupId)], content: "")
        var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
                                     kind: .groupCreate, tags: [], content: "")
        do {
            try createGroupEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        nostrClient.send(event: createGroupEvent, onlyToRelayUrls: [selectedRelay.url])
    }
    
    func joinGroup(ownerAccount: OwnerAccount, group: Group) {
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
    
    func addMember(ownerAccount: OwnerAccount, group: Group, publicKey: String) {
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
    
    func removeMember(ownerAccount: OwnerAccount, group: Group, publicKey: String) {
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
   
    @MainActor
    func sendChatMessage(ownerAccount: OwnerAccount, group: Group, withText text: String) async {
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
        
        if let clientMessage = try? ClientMessage.event(event).string() {
           print(clientMessage)
        }
        
        guard let mainContext = modelContainer?.mainContext else { return }
        let publicKey = ownerAccount.publicKey
        let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
        if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
            chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
            withAnimation {
                mainContext.insert(chatMessage)
                try? mainContext.save()

            }
            nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
        }
        
    }
   
    @MainActor
    func sendChatMessageReply(ownerAccount: OwnerAccount, group: Group, withText text: String, replyChatMessage: ChatMessage) async {
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
        
        guard let mainContext = modelContainer?.mainContext else { return }
        let publicKey = ownerAccount.publicKey
        let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
        if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
            chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
            chatMessage.replyToChatMessage = replyChatMessage
            withAnimation {
                mainContext.insert(chatMessage)
                try? mainContext.save()

            }
            nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
        }
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
        DispatchQueue.main.async {
            self.statuses[relayUrl] = true
        }
    }
    
    func didDisconnect(relayUrl: String) {
        DispatchQueue.main.async {
            self.statuses[relayUrl] = false
        }
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
        case .event(_, let event):
            if event.isValid() {
                process(event: event, relayUrl: relayUrl)
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
                case IdSubGroupList: ()
//                    Task {
//                        await subscribeGroups(withRelayUrl: relayUrl)
////                        await subscribeGroupMemberships(withRelayUrl: relayUrl)
////                        await subscribeGroupAdmins(withRelayUrl: relayUrl)
//                    }
                    Task {
                        await subscribeOwnerGroupMembership(withRelayUrl: relayUrl)
                    }
                case IdSubChatMessages:
                    Task {
                        await connectAllMetadataRelays()
                    }
                case IdSubOwnerGroupMembership:
                    guard let context = self.backgroundContext() else { return }
                    
                    // grab memeber from db
                    let members = try? context.fetch(FetchDescriptor<GroupMember>())
                    print(members)
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
