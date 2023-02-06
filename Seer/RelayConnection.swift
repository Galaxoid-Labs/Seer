//
//  RelayConnection.swift
//  Seer
//
//  Created by Jacob Davis on 2/4/23.
//

import Foundation
import RealmSwift
import NostrKit

class RelayConnection: NSObject {
    
    let relayUrl: String
    let requiresAuth: Bool
    let realm: Realm
    
    var webSocketTask: URLSessionWebSocketTask?
    var connected = false
    var pingTimer: Timer?
    var retryCount = 0
    var maxRetries = 5

    var authors: Set<String> = []
    
//    var lastSeenDirectMessageToTimestamp: Timestamp?
//    var lastSeenDirectMessageFromTimestamp: Timestamp?
    var bootstrapedDirectMessagesTo = false
    var bootstrapedDirectMessagesFrom = false

    var directMessageToSub: Subscription?
    var directMessageFromSub: Subscription?
    var profileSub: Subscription?
    
    let decoder = JSONDecoder()
    
    init(relayUrl: String, requiresAuth: Bool = false) {
        self.relayUrl = relayUrl
        self.requiresAuth = requiresAuth
        self.realm = try! Realm()
    }
    
    func connect() {
        if let url = URL(string: self.relayUrl) {
            if connected {
                self.disconnect()
            }
            let request = URLRequest(url: url)
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.webSocketTask = session.webSocketTask(with: request)
            self.webSocketTask?.resume()
            self.receiveMessage()
        }
    }
    
    func disconnect() {
        self.pingTimer?.invalidate()
        self.webSocketTask?.cancel(with: .goingAway, reason: nil)
        connected = false
    }

    func subscribeProfiles(reusingSubscription: Bool = true) {
        
        let messages = realm.objects(EncryptedMessage.self)
        let messagePublicKeys = Set(Array(messages.compactMap({ $0.toPublicKey })) + Array(messages.compactMap({ $0.publicKey })))
        let authors = Set(Array(realm.objects(PublicKeyMetaData.self)).map({ $0.publicKey }) + messagePublicKeys)
        
        if self.authors != authors {
            self.authors = authors
            if self.authors.count > 0 {
                if let profileSub {
                    if reusingSubscription {
                        self.profileSub = Subscription(filters: [
                            .init(authors: Array(self.authors), eventKinds: [.setMetadata])
                        ], id: profileSub.id)
                    } else {
                        unsubscribeProfiles()
                        self.profileSub = Subscription(filters: [
                            .init(authors: Array(self.authors), eventKinds: [.setMetadata])
                        ])
                    }
                } else {
                    self.profileSub = Subscription(filters: [
                        .init(authors: Array(self.authors), eventKinds: [.setMetadata])
                    ])
                }
                
                if let profileSub, connected {
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
    
    func subscribeDirectMessages(reusingSubscription: Bool = true) {
        
        // TODO: Only get OwnerKeys that have this relay in its list
        let ownerKeys = self.realm.objects(OwnerKey.self)
        
        if ownerKeys.count > 0 {
            
            let ownerPublicKeys = Array(ownerKeys.map({ $0.publicKey }))
            
            if let directMessageToSub {
                if reusingSubscription {
                    self.directMessageToSub = Subscription(filters: [
                        .init(eventKinds: [.encryptedDirectMessage], pubKeyTags: ownerPublicKeys)
                    ], id: directMessageToSub.id)
                } else {
                    unsubscribeDirectToMessages()
                    self.directMessageToSub = Subscription(filters: [
                        .init(eventKinds: [.encryptedDirectMessage], pubKeyTags: ownerPublicKeys)
                    ])
                }
            } else {
                self.directMessageToSub = Subscription(filters: [
                    .init(eventKinds: [.encryptedDirectMessage], pubKeyTags: ownerPublicKeys)
                ])
            }
            
            if let directMessageToSub, connected {
                if let cm = try? ClientMessage.subscribe(directMessageToSub).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            
            if let directMessageFromSub {
                if reusingSubscription {
                    self.directMessageFromSub = Subscription(filters: [
                        .init(authors: ownerPublicKeys, eventKinds: [.encryptedDirectMessage])
                    ], id: directMessageFromSub.id)
                } else {
                    unsubscribeDirectFromMessages()
                    self.directMessageFromSub = Subscription(filters: [
                        .init(authors: ownerPublicKeys, eventKinds: [.encryptedDirectMessage])
                    ])
                }
            } else {
                self.directMessageFromSub = Subscription(filters: [
                    .init(authors: ownerPublicKeys, eventKinds: [.encryptedDirectMessage])
                ])
            }
            
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
        unsubscribeDirectToMessages()
        unsubscribeDirectFromMessages()
    }
    
    func unsubscribeDirectToMessages() {
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
    }
    
    func unsubscribeDirectFromMessages() {
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
    
    private func parse(_ message: RelayMessage) {
        switch message {
        case .event(let id, let event): ()
            
            if event.verified() {
                switch event.kind {
                case .setMetadata:

                    guard let publicKeyMetaData = PublicKeyMetaData.create(from: event) else {
                        return
                    }

                    @ThreadSafe var foundPublicKeyMetaData = realm.object(ofType: PublicKeyMetaData.self, forPrimaryKey: publicKeyMetaData.publicKey)
                    if let foundPublicKeyMetaData {
                        if publicKeyMetaData.createdAt > foundPublicKeyMetaData.createdAt {
                            realm.writeAsync {
                                self.realm.add(publicKeyMetaData, update: .modified)
                            }
                        }
                    } else {
                        realm.writeAsync {
                            self.realm.add(publicKeyMetaData, update: .modified)
                        }
                    }

                case .textNote: ()
                case .recommentServer: ()
                case .encryptedDirectMessage: ()
                    if !event.content.isEmpty, event.content.contains("?iv="), let toPublicKey = event.tags.first(where: { $0.id == "p"})?.otherInformation.first {

                        @ThreadSafe var foundMessage = realm.object(ofType: EncryptedMessage.self, forPrimaryKey: event.id)

                        if foundMessage == nil {
                            let message = EncryptedMessage.create(from: event)
                            message.toPublicKey = toPublicKey
                            message.relayUrls.insert(relayUrl)
                            message.setDecryptedContent()
                            
                            //print(message.decrytedContent)

                            realm.writeAsync {
                                self.realm.add(message, update: .modified)
                            } onComplete: { err in
                                if let err {
                                    print(err)
                                }
                            }

                        } else if let relayUrls = foundMessage?.relayUrls, !relayUrls.contains(relayUrl) {
                            realm.writeAsync {
                                foundMessage?.relayUrls.insert(self.relayUrl)
                            }
                        }

                    }
                case .custom(let kind): ()
//                    if kind == 3 { // Contact list
//                        if let contactSub = self.contactListSubs.first(where: { $0.subscription.id == id }) {
//                            if let indexOf = self.contactListSubs.firstIndex(where: { $0.subscription.id == id }) {
//                                if contactSub.subType == "following" {
//                                    self.contactListSubs[indexOf].publicKeys = Set(event.tags.compactMap({ $0.otherInformation.first }))
//                                } else if contactSub.subType == "followedBy" {
//                                    self.contactListSubs[indexOf].publicKeys.update(with: event.publicKey)
//                                }
//                            }
//                        }
//                    }
                }
            }
            
        case .notice(let notice):
            print(notice)
        case .other(let others): ()
            if others.count == 2 {
                let op = others[0]
                let subscriptionId = others[1]
                if op == "EOSE" {

                    // MARK: - Handle setmetadata EOSE
                    if subscriptionId == profileSub?.id {
                        print("👁️ Seer => Profiles EOSE - Sub ID: \(subscriptionId)\n    Relay URL: \(relayUrl)")
                    }

                    // MARK: - Handle DM EOSE
                    if subscriptionId == directMessageToSub?.id || subscriptionId == directMessageFromSub?.id {
                        print("👁️ Seer => Direct Messages EOSE - Sub ID: \(subscriptionId), Relay URL: \(relayUrl)")
                        self.subscribeProfiles()
                    }

                }
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
                    print("👁️ Seer => 🤷‍♂️ Unknown type received from Relay Connected at URL: \(self?.relayUrl ?? "")")
                    self?.receiveMessage()
                }
            case .failure(let error):
                self?.retryConnect()
                print(error.localizedDescription)
            }
        })
    }
    
    private func retryConnect() {
        if !connected {
            if retryCount < maxRetries {
                print("👁️ Seer => 🔌 Trying reconnect to Relay at URL: \(self.relayUrl)")
                self.connect()
            } else {
                print("👁️ Seer => 🔌 Giving up reconnect to Relay at URL: \(self.relayUrl)")
            }
        }
    }
    
    private func startPing() {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] timer in
                self?.webSocketTask?.sendPing(pongReceiveHandler: { error in
                    if let error = error {
                        print("👁️ Seer => 🔌 Ping sent to Relay Connected at URL: \(self?.relayUrl ?? "") Failed with Error \(error.localizedDescription)")
                        self?.retryConnect()
                    } else {
                        //print("👁️ Seer => 🔌 Ping sent to Relay Connected at URL: \(self?.relayUrl ?? "")")
                        // no-op
                    }
                })
            }
        }
    }
    
    private func publish(event: Event) {
        if let message = try? ClientMessage.event(event).string(), connected {
            self.webSocketTask?.send(.string(message), completionHandler: { error in
                if let error {
                    print(error)
                }
            })
        }
    }
    
    private func subscribe() {
        DispatchQueue.main.async {
            self.subscribeDirectMessages()
            self.subscribeProfiles()
        }
    }
    
    private func unsubscribe() {
        DispatchQueue.main.async {
            self.unsubscribeProfiles()
            self.unsubscribeDirectMessages()
        }
    }

}

extension RelayConnection: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connected = true
        authors.removeAll() // TODO:
        startPing()
        subscribe()
        retryCount = 0
        print("👁️ Seer => 🔌 Relay Connected at URL: \(self.relayUrl)")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connected = false
        print("👁️ Seer => 🔌 Relay Disconnected at URL: \(self.relayUrl)")
        if closeCode != .normalClosure && closeCode != .goingAway {
            retryConnect()
        }
    }
}
