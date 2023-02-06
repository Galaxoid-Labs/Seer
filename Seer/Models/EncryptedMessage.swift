//
//  EncryptedMessage.swift
//  Seer
//
//  Created by Jacob Davis on 2/5/23.
//

import Foundation
import NostrKit
import RealmSwift
import CryptoKit
import SwiftUI

class EncryptedMessage: Object, ObjectKeyIdentifiable {
    
    @Persisted(primaryKey: true) var id: String
    @Persisted var publicKey: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    @Persisted var toPublicKey: String
    @Persisted var relayUrls: MutableSet<String>
    @Persisted var read: Bool
    
    @Persisted var decryptedContent: String
    
    var ownerKey: OwnerKey? {
        guard let realm = try? Realm() else { return nil }
        return realm.object(ofType: OwnerKey.self, forPrimaryKey: publicKey)
        ?? realm.object(ofType: OwnerKey.self, forPrimaryKey: toPublicKey)
    }
    
    var contentFormatted: AttributedString? {
        var attr = try? AttributedString(markdown: decryptedContent,
                                         options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        if let runs = attr?.runs {
            for run in runs {
                if run.link != nil {
                    attr?[run.range].underlineStyle = .single
                    attr?[run.range].foregroundColor = Color.red
                }
            }
        }
        return attr
    }
    
    var imageUrls: [URL] {
        if let content = contentFormatted {
            return content.runs.compactMap({
                if let link = $0.link, link.isImageType() {
                    return link.absoluteURL
                }
                return nil
            })
        }
        return []
    }
    
    var videoUrls: [URL] {
        if let content = contentFormatted {
            return content.runs.compactMap({
                if let link = $0.link, link.isVideoType() {
                    return link.absoluteURL
                }
                return nil
            })
        }
        return []
    }
    
    func decryptContent() -> String? {
        guard let ownerKey else { return nil }
        guard let keypair = ownerKey.getKeyPair() else { return nil }
        let otherPublicKey = publicKey == ownerKey.publicKey ? toPublicKey : publicKey
        return KeyPair.decryptDirectMessageContent(withPrivateKey: keypair.privateKey, pubkey: otherPublicKey, content: content) ?? ""
    }
    
    func setDecryptedContent() {
        self.decryptedContent = decryptContent() ?? ""
    }
    
    // Return the opposite PublicKeyMetaData from whats passed in..
    func getOtherPublicMetaData(whereOwnerKey ownerKey: OwnerKey) -> PublicKeyMetaData? {
        guard let realm = try? Realm() else { return nil }
        return publicKey == ownerKey.publicKey
        ? realm.object(ofType: PublicKeyMetaData.self, forPrimaryKey: toPublicKey)
        : realm.object(ofType: PublicKeyMetaData.self, forPrimaryKey: publicKey)
    }

}



extension EncryptedMessage {
    
    static func create(from event: Event) -> EncryptedMessage {
        return EncryptedMessage(value: ["id": event.id, "publicKey": event.publicKey, "content": event.content, "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])
    }
    
    static let preview = EncryptedMessage(value: [
        "id": "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
        "publicKey": "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
        "content": "bac",
        "toPublicKey": "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
        "read": false,
        "decryptedContent": "Hello heres some content http://google.com",
        "createdAt": Date(),
    ])

}
