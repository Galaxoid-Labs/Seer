//
//  OwnerKey.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import Foundation
import RealmSwift
import NostrKit
import KeychainAccess

class OwnerKey: Object, ObjectKeyIdentifiable {
    
    @Persisted(primaryKey: true) var publicKey: String
    
    @Persisted var metaDataRelayIds: MutableSet<String>
    @Persisted var messageRelayIds: MutableSet<String>
    
    var bech32PublicKey: String? {
        KeyPair.bech32PublicKey(fromHex: publicKey)
    }
    
    var bestPublicName: String {
        if let publicKeyMetaData {
            return publicKeyMetaData.bestPublicName
        } else {
            return bech32PublicKey ?? publicKey
        }
    }
    
    var publicKeyMetaData: PublicKeyMetaData? {
        return try? Realm().object(ofType: PublicKeyMetaData.self, forPrimaryKey: publicKey)
    }
    
    func getKeyPair() -> KeyPair? {
        let keychain = Keychain(service: "seer")
        guard let privateKey = try? keychain.getString(publicKey) else {
            return nil
        }
        return try? KeyPair(privateKey: privateKey)
    }
    
    func getLatestMessage() -> EncryptedMessage? {
        let b = try? Realm().objects(EncryptedMessage.self)
            .where({ $0.toPublicKey == publicKey || $0.publicKey == publicKey })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
        
        print(b)
        return b
    }
    
    func getTotalUnreadCount() -> Int {
        guard let realm = try? Realm() else { return 0 }
        let b = realm.objects(EncryptedMessage.self)
            .where({ $0.toPublicKey == publicKey || $0.publicKey == publicKey })
            .where({ $0.read == false })
        //print(b)
        return b.count
    }
    
    func getInboxUnreadCount() -> Int {
        guard let realm = try? Realm() else { return 0 }
        let publicKeyMetaDatas = realm.objects(PublicKeyMetaData.self)
            .filter({ $0.hasBeenContactBy(ownerKey: self) == true && $0.publicKey != self.publicKey })
        let pks = Array(publicKeyMetaDatas.map({ $0.publicKey }))
        let messages = realm.objects(EncryptedMessage.self)
            .where({ $0.read == false })
            .where({ $0.publicKey.in(pks) || $0.toPublicKey.in(pks) })
        return messages.count
    }
    
    func getUknownUnreadCount() -> Int {
        guard let realm = try? Realm() else { return 0 }
        let publicKeyMetaDatas = realm.objects(PublicKeyMetaData.self).filter({ $0.hasBeenContactBy(ownerKey: self) == false && $0.publicKey != self.publicKey })
        let pks = Array(publicKeyMetaDatas.map({ $0.publicKey }))
        let messages = realm.objects(EncryptedMessage.self)
            .where({ $0.read == false })
            .where({ $0.publicKey.in(pks) || $0.toPublicKey.in(pks) })
        return messages.count
    }
}


extension OwnerKey {

    static func create(withPrivateKey: String, enablingAllrelays: Bool = true) -> OwnerKey? {
        if let keypair = OwnerKey.keyPairFrom(string: withPrivateKey) {
            OwnerKey.saveKeyPairToKeychain(keyPair: keypair)
            let ownerKey = OwnerKey(value: ["publicKey": keypair.publicKey])
            if enablingAllrelays {
                if let relays = try? Realm().objects(Relay.self).map({ $0.url }) {
                    ownerKey.metaDataRelayIds.insert(objectsIn: relays)
                    ownerKey.messageRelayIds.insert(objectsIn: relays)
                }
            }
            return ownerKey
        }
        return nil
    }
    
    static func restore(fromPublicKey: String, enablingAllrelays: Bool = true) -> OwnerKey? {
        let ownerKey = OwnerKey(value: ["publicKey": fromPublicKey])
        if enablingAllrelays {
            if let relays = try? Realm().objects(Relay.self).map({ $0.url }) {
                ownerKey.metaDataRelayIds.insert(objectsIn: relays)
                ownerKey.messageRelayIds.insert(objectsIn: relays)
            }
        }
        if let _ = ownerKey.getKeyPair() {
            return ownerKey
        }
        return nil
    }
    
    static func createNew(enablingAllrelays: Bool = true) -> OwnerKey? {
        if let keypair = try? KeyPair() {
            OwnerKey.saveKeyPairToKeychain(keyPair: keypair)
            let ownerKey = OwnerKey(value: ["publicKey": keypair.publicKey])
            if enablingAllrelays {
                if let relays = try? Realm().objects(Relay.self).map({ $0.url }) {
                    ownerKey.metaDataRelayIds.insert(objectsIn: relays)
                    ownerKey.messageRelayIds.insert(objectsIn: relays)
                }
            }
            return ownerKey
        }
        return nil
    }
    
    static let preview = OwnerKey(value: [
        "publicKey": "npub1ch8a4xxsru2jkdynmx27a4xdknv72k5h8yjld702y3mf5k3puauqmszh48",
        "selected": true
    ])
    
    static let preview2 = OwnerKey(value: [
        "publicKey": "npub1ch8a4xxsru2jkdynmx27a4xdknv72k5h8yjld70",
        "selected": true
    ])
    
    static func saveKeyPairToKeychain(keyPair: KeyPair) {
        let keychain = Keychain(service: "seer")
        try? keychain.set(keyPair.privateKey, key: keyPair.publicKey)
    }
    
    static func keyPairFrom(string: String) -> KeyPair? {
        if string.hasPrefix("nsec") {
            return try? KeyPair(bech32PrivateKey: string)
        } else {
            return try? KeyPair(privateKey: string)
        }
    }
}
