//
//  NostrRelay.swift
//  Seer
//
//  Created by Jacob Davis on 11/8/22.
//

import Foundation
import RealmSwift
import NostrKit

class NostrRelay: NSObject {
    
    struct SetMetaDataEventData: Codable {
        var name: String?
        var about: String?
        var picture: String?
        var nip05: String?
        var lud06: String?
        var lud16: String?
        var display_name: String?
        var website: String?
    }
    
    let urlString: String
    let realm: Realm
    
    var webSocketTask: URLSessionWebSocketTask?
    var connected = false
    var pingTimer: Timer?
    var retryCount = 0
    var maxRetries = 5
    
    var subs: Int = 0
    
    var authors: Set<String> = []
    
    var tempProfiles: [RUserProfile] = []
    var tempDirectMessages: [REncryptedDirectMessage] = []
    
    var lastSeenDirectMessageToTimestamp: Timestamp?
    var lastSeenDirectMessageFromTimestamp: Timestamp?
    var bootstrapedProfiles = false
    var bootstrapedDirectMessagesTo = false
    var bootstrapedDirectMessagesFrom = false
    
    var directMessageToSub: Subscription?
    var directMessageFromSub: Subscription?
    var profileSub: Subscription?
    
    var contactListSubs: [ContactListSub] = []
    
    let decoder = JSONDecoder()
    
    init(urlString: String, realm: Realm) {
        self.urlString = urlString
        self.realm = realm
    }
    
    func connect() {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.webSocketTask = session.webSocketTask(with: request)
            self.webSocketTask?.resume()
            self.receiveMessage()
        }
    }
    
    func publish(event: Event) {
        if let message = try? ClientMessage.event(event).string(), connected {
            print(message)
            self.webSocketTask?.send(.string(message), completionHandler: { error in
                if let error {
                    print(error)
                }
            })
        }
    }
    
    func needsProfileSub() -> Bool {
        if !authors.isEmpty {
            if let currentAuthors = self.profileSub?.filters.first.map({ $0.authors }) ?? [] {
                if authors != Set(currentAuthors) {
                    return true
                }
            }
        }
        return false
    }

    func subscribeProfiles() {
        let messages = realm.objects(REncryptedDirectMessage.self)
        self.authors = Set(Array(messages.compactMap({ $0.toUserProfile?.publicKey })) +  Array(messages.compactMap({ $0.userProfile?.publicKey })))
        print(self.authors.count)
        if needsProfileSub() {
            if profileSub != nil {
                unsubscribeProfiles()
            }
            self.profileSub = Subscription(filters: [
                .init(authors: Array(self.authors), eventKinds: [.setMetadata])
            ])
            if let profileSub {
                if let cm = try? ClientMessage.subscribe(profileSub).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error = error {
                            print(error)
                        }
                    })
                }
            }
        }
    }

    func unsubscribeProfiles() {
        if let profileSub = profileSub, connected {
            if let cm = try? ClientMessage.unsubscribe(profileSub.id).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error = error {
                        print(error)
                    }
                })
            }
        }
        self.profileSub = nil
    }

    func subscribeDirectMessages() {
        
        if let selectedUserProfile = NostrData.shared.selectedUserProfile() {
            if directMessageToSub != nil || directMessageFromSub != nil {
                unsubscribeDirectMessages()
            }
            
            self.directMessageToSub = Subscription(filters: [
                .init(eventKinds: [.custom(4)], pubKeyTags: [selectedUserProfile.publicKey], since: lastSeenDirectMessageToTimestamp)
            ])
            
            if let directMessageToSub, connected {
                if let cm = try? ClientMessage.subscribe(directMessageToSub).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            
            self.directMessageFromSub = Subscription(filters: [
                .init(authors: [selectedUserProfile.publicKey], eventKinds: [.custom(4)], since: lastSeenDirectMessageFromTimestamp)
            ])
            
            if let directMessageFromSub, connected {
                if let cm = try? ClientMessage.subscribe(directMessageFromSub).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
        }
        
    }
    
    func unsubscribeDirectMessages() {
        if let directMessageSub = directMessageToSub, connected {
            if let cm = try? ClientMessage.unsubscribe(directMessageSub.id).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error {
                        print(error)
                    }
                })
            }
        }
        self.directMessageToSub = nil
        
        if let directMessageFromSub = directMessageFromSub, connected {
            if let cm = try? ClientMessage.unsubscribe(directMessageFromSub.id).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error {
                        print(error)
                    }
                })
            }
        }
        self.directMessageFromSub = nil
    }
    
    struct ContactListSub {
        let subscription: Subscription
        let subType: String
        var publicKey: String
        var publicKeys: Set<String>
    }
    
    func subscribeContactList(forPublicKey publicKey: String) {
        if connected {
            
            let subs = self.contactListSubs.filter({ $0.publicKey == publicKey })
            
            for sub in subs {
                if let followingSub = try? ClientMessage.unsubscribe(sub.subscription.id).string() {
                    self.webSocketTask?.send(.string(followingSub), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            
            self.contactListSubs.removeAll(where: { $0.publicKey == publicKey })
            
            let followingSub = Subscription(filters: [.init(authors: [publicKey], eventKinds: [.custom(3)])])
            let a = ContactListSub(subscription: followingSub, subType: "following", publicKey: publicKey, publicKeys: [])
            
            let followedSub = Subscription(filters: [.init(eventKinds: [.custom(3)], pubKeyTags: [publicKey])])
            let b = ContactListSub(subscription: followedSub, subType: "followedBy", publicKey: publicKey, publicKeys: [])
            
            self.contactListSubs.append(contentsOf: [a,b])
            
            for sub in self.contactListSubs {
                if let cm = try? ClientMessage.subscribe(sub.subscription).string() {
                    print(cm)
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
        }
    }
    
    func unsubscribeContactList(withId: String) {
        if let indexOf = self.contactListSubs.firstIndex(where: { $0.subscription.id == withId }) {
            let sub = self.contactListSubs[indexOf]
            if connected {
                if let cm = try? ClientMessage.unsubscribe(sub.subscription.id).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            self.contactListSubs.remove(at: indexOf)
        }
    }
    
    func unsubscribeContactListForAll() {
        if connected {
            for sub in self.contactListSubs {
                if let cm = try? ClientMessage.unsubscribe(sub.subscription.id).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
        }
        self.contactListSubs.removeAll()
    }
    
    func subscribe() {
        DispatchQueue.main.async {
            self.subscribeProfiles()
            self.subscribeDirectMessages()
        }
    }
    
    func unsubscribe() {
        DispatchQueue.main.async {
            self.unsubscribeProfiles()
            self.unsubscribeDirectMessages()
            self.unsubscribeContactListForAll()
        }
    }
    
    func disconnect() {
        self.pingTimer?.invalidate()
        self.webSocketTask?.cancel(with: .goingAway, reason: nil)
        connected = false
    }
    
    private func retryConnect() {
        if !connected {
            print("Websocket Closed")
            if retryCount < maxRetries {
                print("Trying reconnect")
                self.connect()
            } else {
                print("Giving up reconnect")
            }
        }
    }
    
    private func receiveMessage() {
        self.webSocketTask?.receive(completionHandler: { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    self?.receiveMessage()
                case .string(let messageString):
                    if let relayMessage = try? RelayMessage(text: messageString) {
                        DispatchQueue.main.async {
                            self?.parse(relayMessage)
                        }
                    }
                    self?.receiveMessage()
                @unknown default:
                    print("Unknown type received from WebSocket")
                    self?.receiveMessage()
                }
            case .failure(let error):
                self?.retryConnect()
                print(error)
            }
        })
    }
    
    private func startPing() {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
                self?.webSocketTask?.sendPing(pongReceiveHandler: { error in
                    if let error = error {
                        print("Failed with Error \(error.localizedDescription)")
                        self?.retryConnect()
                    } else {
                        // no-op
                    }
                })
            }
        }
    }
    
    private func parse(_ message: RelayMessage) {
        switch message {
        case .event(let id, let event):
            
            if event.verified() {
                switch event.kind {
                case .setMetadata:
                    
                    guard let userProfile = RUserProfile.create(with: event) else {
                        return
                    }
                    
                    if event.publicKey == "32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245" {
                        print(event)
                    }
                    
                    if self.bootstrapedProfiles {
                        realm.writeAsync {
                            self.realm.add(userProfile, update: .modified)
                        }
                    } else {
                        self.tempProfiles.append(userProfile)
                    }
                    
                case .textNote: ()
                case .recommentServer: ()
                case .encryptedDirectMessage:
                    if !event.content.isEmpty, event.content.contains("?iv="), let toPublickey = event.tags.first(where: { $0.id == "p"})?.otherInformation.first {

                        @ThreadSafe var message = realm.object(ofType: REncryptedDirectMessage.self, forPrimaryKey: event.id)
                        
                        if message == nil {
                            let directMessage = REncryptedDirectMessage.create(with: event)
                            
                            @ThreadSafe var profile = realm.object(ofType: RUserProfile.self, forPrimaryKey: event.publicKey)
                            if profile != nil {
                                directMessage.userProfile = profile
                            } else {
                                directMessage.userProfile = RUserProfile.createEmpty(withPublicKey: event.publicKey)
                            }
                            
                            @ThreadSafe var toProfile = realm.object(ofType: RUserProfile.self, forPrimaryKey: toPublickey)
                            if toProfile != nil {
                                directMessage.toUserProfile = toProfile
                            } else {
                                directMessage.toUserProfile = RUserProfile.createEmpty(withPublicKey: toPublickey)
                            }
                            
                            directMessage.decryptedContent = directMessage.decryptContent()
                            
                            if self.bootstrapedDirectMessagesTo && self.bootstrapedDirectMessagesFrom {
                                realm.writeAsync {
                                    self.realm.add(directMessage, update: .modified)
                                } onComplete: { err in
                                    if let err {
                                        print(err)
                                    } else {
                                        self.subscribeProfiles()
                                    }
                                }
                            } else {
                                self.tempDirectMessages.append(directMessage)
                            }
                            
                            if id == self.directMessageToSub?.id {
                                self.lastSeenDirectMessageToTimestamp = event.createdAt
                            } else if id == self.directMessageFromSub?.id {
                                self.lastSeenDirectMessageFromTimestamp = event.createdAt
                            }
                            
                        }
                        
                    }
                case .custom(let kind):
                    if kind == 3 { // Contact list
                        if let contactSub = self.contactListSubs.first(where: { $0.subscription.id == id }) {
                            if let indexOf = self.contactListSubs.firstIndex(where: { $0.subscription.id == id }) {
                                if contactSub.subType == "following" {
                                    self.contactListSubs[indexOf].publicKeys = Set(event.tags.compactMap({ $0.otherInformation.first }))
                                } else if contactSub.subType == "followedBy" {
                                    self.contactListSubs[indexOf].publicKeys.update(with: event.publicKey)
                                }
                            }
                        }
                    }
                }
            }
            
        case .notice(let notice):
            print(notice)
        case .other(let others): ()
            if others.count == 2 {
                let op = others[0]
                let subscriptionId = others[1]
                if op == "EOSE" {
                    
                    // MARK: - Handle contact list EOSE
                    if let contactSub = self.contactListSubs.first(where: { $0.subscription.id == subscriptionId }) {
                        
                        @ThreadSafe var contactList = self.realm.object(ofType: RContactList.self, forPrimaryKey: contactSub.publicKey)

                        if contactList == nil {
                            try? self.realm.write {
                                contactList = self.realm.create(RContactList.self, value: RContactList.createEmpty(withPublicKey: contactSub.publicKey))
                            }
                        }
                        
                        if let contactList {

                            if contactSub.subType == "following" {

                                self.realm.writeAsync {
                                    
                                    contactList.following.removeAll()

                                    for pubKey in contactSub.publicKeys {
                                        @ThreadSafe var profile = self.realm.object(ofType: RUserProfile.self, forPrimaryKey: pubKey)
                                        if let profile {
                                            contactList.following.append(profile)
                                        } else {
                                            let profile = self.realm.create(RUserProfile.self, value: RUserProfile.createEmpty(withPublicKey: pubKey), update: .modified)
                                            contactList.following.append(profile)
                                        }
                                    }
                                    
                                }


                            } else if contactSub.subType == "followedBy" {

                                self.realm.writeAsync {
                                    
                                    contactList.followedBy.removeAll()

                                    for pubKey in contactSub.publicKeys {
                                        @ThreadSafe var profile = self.realm.object(ofType: RUserProfile.self, forPrimaryKey: pubKey)
                                        if let profile {
                                            contactList.followedBy.append(profile)
                                        } else {
                                            let profile = self.realm.create(RUserProfile.self, value: RUserProfile.createEmpty(withPublicKey: pubKey), update: .modified)
                                            contactList.followedBy.append(profile)
                                        }
                                    }
                                }

                            }

                        }

                        print("Contact List EOSE - Sub ID: \(subscriptionId)")
                        self.unsubscribeContactList(withId: subscriptionId)
                        self.subscribeProfiles()
                        
                    }
                    
                    // MARK: - Handle setmetadata EOSE
                    if subscriptionId == profileSub?.id && !self.bootstrapedProfiles {
                        
                        print("Profiles EOSE - Sub ID: \(subscriptionId)")
                        
                        self.bootstrapedProfiles = true
                        realm.writeAsync {
                            self.realm.add(self.tempProfiles, update: .modified)
                            self.tempProfiles.removeAll()
                        } onComplete: { err in
                            if let err {
                                print(err)
                            }
                            print(self.realm.objects(RUserProfile.self).count)
                        }
                    }
                    
                    // MARK: - Handle DM EOSE
                    if subscriptionId == directMessageToSub?.id && !self.bootstrapedDirectMessagesTo {
                        
                        print("Direct Messages EOSE - Sub ID: \(subscriptionId)")
                        
                        self.bootstrapedDirectMessagesTo = true
                        
                        realm.writeAsync {
                            self.realm.add(self.tempDirectMessages, update: .modified)
                            self.tempDirectMessages.removeAll()
                        } onComplete: { err in
                            if let err {
                                print(err)
                            } else {
                                if self.bootstrapedDirectMessagesFrom && self.bootstrapedDirectMessagesTo {
                                    let profiles = self.realm.objects(RUserProfile.self)
                                    self.authors = Set(profiles.map({ $0.publicKey }))
                                    self.subscribeProfiles()
                                }
                            }
                        }
                        
                    }
                    
                    if subscriptionId == directMessageFromSub?.id && !self.bootstrapedDirectMessagesFrom {
                        
                        print("Direct Messages EOSE - Sub ID: \(subscriptionId)")
                        
                        self.bootstrapedDirectMessagesFrom = true
                        
                        realm.writeAsync {
                            self.realm.add(self.tempDirectMessages, update: .modified)
                            self.tempDirectMessages.removeAll()
                        } onComplete: { err in
                            if let err {
                                print(err)
                            } else {
                                if self.bootstrapedDirectMessagesFrom && self.bootstrapedDirectMessagesTo {
                                    let profiles = self.realm.objects(RUserProfile.self)
                                    self.authors = Set(profiles.map({ $0.publicKey }))
                                    self.subscribeProfiles()
                                }
                            }
                        }
                        
                    }
                    
                }
            }
        }
    }

}

extension NostrRelay: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connected = true
        authors.removeAll() // TODO:
        startPing()
        subscribe()
        retryCount = 0
        print("Websocket Opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connected = false
        print("Websocket Closed")
        if closeCode != .normalClosure && closeCode != .goingAway {
            retryConnect()
        }
    }
}
