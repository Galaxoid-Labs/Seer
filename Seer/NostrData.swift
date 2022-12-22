//
//  NostrData.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import Foundation
import NostrKit
import RealmSwift

class NostrData: ObservableObject {

    var nostrRelays: [NostrRelay] = []
    
    @ObservedResults(ROwnedUserProfile.self) var ownedUserProfileResults
    var selectedOwnerUserProfile: ROwnedUserProfile? {
        ownedUserProfileResults.first(where: { $0.selected == true })
    }

    let realm: Realm
    static let shared = NostrData()
    
    private init() {
        let config = Realm.Configuration(schemaVersion: 11)
        Realm.Configuration.defaultConfiguration = config
        self.realm = try! Realm()
        self.realm.autorefresh = true
        bootstrapRelays()
    }
    
    func initPreview() -> NostrData {
//        userProfiles = [UserProfile.preview]
//        textNotes = [TextNote.preview]
        return .shared
    }
    
    func bootstrapRelays() {
        self.nostrRelays.append(NostrRelay(urlString: "wss://relay.damus.io", realm: realm))
//        self.nostrRelays.append(NostrRelay(urlString: "wss://nostr-pub.wellorder.net", realm: realm))
        for relay in nostrRelays {
            relay.connect()
        }
    }
    
    func disconnect() {
        for relay in nostrRelays {
            relay.unsubscribe()
            relay.disconnect()
        }
    }
    
    func reconnect() {
        for relay in nostrRelays {
            if !relay.connected {
                relay.connect()
            }
        }
    }
    
    func fetchContactList(forPublicKey publicKey: String) {
        for relay in nostrRelays {
            relay.subscribeContactList(forPublicKey: publicKey)
        }
    }

    func selectedUserProfile() -> ROwnedUserProfile? {
        if let ownedUserProfile = realm.objects(ROwnedUserProfile.self).where({ $0.selected == true }).first {
            if let _ = privateKey(forPublicKey: ownedUserProfile.publicKey) {
                return ownedUserProfile
            }
        }
        return nil
    }

    func privateKey(forPublicKey publicKey: String) -> String? {
        if let pk = UserDefaults.standard.string(forKey: publicKey) {
            return pk
        }
        return nil
    }
    
    func save(privateKey: String, forPublicKey publicKey: String) {
        // TEMPORARY. Will save to keychain.
        UserDefaults.standard.set(privateKey, forKey: publicKey)
        if let ownedUserProfile = realm.object(ofType: ROwnedUserProfile.self, forPrimaryKey: publicKey) {
            realm.writeAsync {
                ownedUserProfile.selected = true
            }
        } else {
            let ownedUserProfile = ROwnedUserProfile.create(withPublicKey: publicKey)
            ownedUserProfile.selected = true
            realm.writeAsync {
                self.realm.add(ownedUserProfile)
            }
        }
        self.disconnect()
        self.reconnect()
    }
    
    func createEncyrpedDirectMessageEvent(withContent content: String, forPublicKey publicKey: String) -> Bool {
        
        guard let selectedOwnerUserProfile, let privateKey = privateKey(forPublicKey: selectedOwnerUserProfile.publicKey) else {
            return false
        }
        
        guard let encryptedContent = KeyPair.encryptDirectMessageContent(withPrivatekey: privateKey,
                                                                         pubkey: publicKey, content: content) else {
            return false
        }
        
        guard let keypair = try? KeyPair(privateKey: privateKey) else {
            return false
        }
    
        let tag = EventTag.pubKey(publicKey: publicKey)
        guard let event = try? Event(keyPair: keypair, kind: .custom(4), tags: [tag], content: encryptedContent) else {
            return false
        }
        
        for relay in nostrRelays {
            relay.publish(event: event)
        }
        
        return true

    }

}
