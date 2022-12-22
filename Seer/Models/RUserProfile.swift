//
//  RUserProfile.swift
//  Seer
//
//  Created by Jacob Davis on 11/2/22.
//

import Foundation
import RealmSwift
import NostrKit

class RUserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var publicKey: String
    @Persisted var name: String
    @Persisted var about: String
    @Persisted var picture: String
    @Persisted var nip05: String
    @Persisted var lud06: String
    @Persisted var lud16: String
    @Persisted var displayName: String
    @Persisted var website: String
    @Persisted var createdAt: Date
    
    var avatarUrl: URL? {
        return URL(string: picture)
    }
    
    var aboutFormatted: AttributedString? {
        if !about.isEmpty {
            return try? AttributedString(markdown: about,
                                         options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        }
        return nil
    }
    
    var bech32PublicKey: String {
        KeyPair.bech32PublicKey(fromHex: publicKey) ?? publicKey
    }
    
    func getLatestMessage() -> REncryptedDirectMessage? {
        return try? Realm().objects(REncryptedDirectMessage.self)
            .where({ $0.userProfile.publicKey == publicKey || $0.toUserProfile.publicKey == publicKey })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }
    
    func hasContacted() -> Bool {
        if let realm = try? Realm() {
            if let selectedOwnerUserProfile = realm.objects(ROwnedUserProfile.self).first(where: { $0.selected == true }) {
                return realm.objects(REncryptedDirectMessage.self).first(where: { $0.publicKey == selectedOwnerUserProfile.publicKey && $0.toUserProfile?.publicKey == publicKey }) != nil
            }
        }
        return false
    }
    
}

extension RUserProfile {
    
    static func create(with event: Event) -> RUserProfile? {
        do {
            let decoder = JSONDecoder()
            let eventData = try decoder.decode(NostrRelay.SetMetaDataEventData.self, from: Data(event.content.utf8))
            let value: [String: Any] = ["publicKey": event.publicKey,
                                        "name": eventData.name ?? "",
                                        "about": eventData.about ?? "",
                                        "picture": eventData.picture ?? "",
                                        "nip05": eventData.nip05 ?? "",
                                        "lud06": eventData.lud06 ?? "",
                                        "lud16": eventData.lud16 ?? "",
                                        "website": eventData.website ?? "",
                                        "displayName": eventData.display_name ?? "",
                                        "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp)),
            ]
            return RUserProfile(value: value)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func createEmpty(withPublicKey publicKey: String) -> RUserProfile {
        return RUserProfile(value: ["publicKey": publicKey])
    }
    
    static let preview = RUserProfile(value: [
        "publicKey": "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
        "name": "ismyhc",
        "about": "Founder and CEO at Galaxoid Labs. Working on lots of cool stuff around Bitcoin.",
        "picture": "https://pbs.twimg.com/profile_images/1571992959591096326/ZKY_3l2x_400x400.jpg",
        "nip05": "galaxoidlabs.com",
        "lud06": "lnurl1dp68gurn8ghj7ctsdyh85etzv4jx2efwd9hj7a3s9aex2ut4v4ehgttnw3shg6tr943ksctjvajhxte4v4nxve3kvdnz6cfe893z6drxvgcz6c34vcez6wfsxsmxgvecvsukgceevgt8jy",
        "lud16": "ismyhc@zbd.gg",
        "website": "jacob@galaxoidlabs.com",
        "displayName": "Jacob Davis",
        "createdAt": Date(),
    ])
}
