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
        return try? Realm().objects(EncryptedMessage.self)
            .where({ $0.toPublicKey == publicKey || $0.publicKey == publicKey })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }
    
    func getTotalUnreadCount() -> Int {
        guard let realm = try? Realm() else { return 0 }
        return realm.objects(EncryptedMessage.self)
            .where({ $0.toPublicKey == publicKey || $0.publicKey == publicKey })
            .where({ $0.read == false })
            .count
    }
}


extension OwnerKey {

    static func create(withPrivateKey: String) -> OwnerKey? {
        if let keypair = OwnerKey.keyPairFrom(string: withPrivateKey) {
            OwnerKey.saveKeyPairToKeychain(keyPair: keypair)
            return OwnerKey(value: ["publicKey": keypair.publicKey, "selected": false])
        }
        return nil
    }
    
    static func restore(fromPublicKey: String) -> OwnerKey? {
        let ownerKey = OwnerKey(value: ["publicKey": fromPublicKey, "selected": false])
        if let _ = ownerKey.getKeyPair() {
            return ownerKey
        }
        return nil
    }
    
    static func createNew() -> OwnerKey? {
        if let keypair = try? KeyPair() {
            OwnerKey.saveKeyPairToKeychain(keyPair: keypair)
            return OwnerKey(value: ["publicKey": keypair.publicKey, "selected": false])
        }
        return nil
    }
    
    static let preview = OwnerKey(value: [
        "publicKey": "lasdfjenandlfieasdnf",
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
