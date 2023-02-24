//
//  PublicKeyMetaData.swift
//  Seer
//
//  Created by Jacob Davis on 2/3/23.
//

import Foundation
import RealmSwift
import NostrKit

class PublicKeyMetaData: Object, ObjectKeyIdentifiable {
    
    @Persisted(primaryKey: true) var publicKey: String
    
    @Persisted var name: String
    @Persisted var about: String
    @Persisted var picture: String
    @Persisted var nip05: String
    @Persisted var lud06: String
    @Persisted var lud16: String
    @Persisted var createdAt: Date
    
    @Persisted var nip05Verified: Bool
    
    @Persisted var relayUrls: MutableSet<String>
    
    var bech32PublicKey: String? {
        KeyPair.bech32PublicKey(fromHex: publicKey)
    }
    
    var bestPublicName: String {
        if !nip05.isEmpty {
            return nip05.replacingOccurrences(of: "_@", with: "")
        } else if !name.isEmpty {
            return name
        } else {
            return bech32PublicKey ?? publicKey
        }
    }
    
    var legitNipO5: Bool {
        if let nip05Components {
            return nip05Components.count == 2 // TODO: Better check here...
        }
        return false
    }
    
    var nip05Components: [String]? {
        if !nip05.isEmpty {
            return nip05.components(separatedBy: "@")
        }
        return nil
    }
    
    var nip05Url: URL? {
        guard let nip05Components else { return nil }
        if nip05Components.count != 2 {
            return nil
        }
        return URL(string: "https://\(nip05Components[1])/.well-known/nostr.json?name=\(nip05Components[0])")
    }
    
    func bestPublicNameIsKey() -> Bool {
        if nip05.isEmpty && name.isEmpty {
            return true
        }
        return false
    }
    
    func getLatestMessage() -> EncryptedMessage? {
        return try? Realm().objects(EncryptedMessage.self)
            .where({ $0.toPublicKey == publicKey || $0.publicKey == publicKey })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }
    
    func hasUnreadMessages() -> Bool {
        return ((try? Realm()
            .objects(EncryptedMessage.self).where({ $0.read == false })
            .first != nil ? true : false) != nil)
    }
    
    func hasBeenContactBy(ownerKey: OwnerKey) -> Bool {
        if let _ = try? Realm().objects(EncryptedMessage.self)
            .where({ $0.publicKey == ownerKey.publicKey && $0.toPublicKey == publicKey })
            .first {
            return true
        }
        return false
    }

}

extension PublicKeyMetaData {
    
    static func create(withPublicKey publicKey: String) -> PublicKeyMetaData {
        return PublicKeyMetaData(value: ["publicKey": publicKey,
                                         "createdAt": Date.distantPast])
    }
    
    static func create(from event: Event) -> PublicKeyMetaData? {
        let retval = PublicKeyMetaData(value: ["publicKey": event.publicKey,
                                               "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])
        let decoder = JSONDecoder()
        if let contentData = try? decoder.decode(MetaDataContentData.self, from: Data(event.content.utf8)) {
            retval.name = contentData.name ?? ""
            retval.about = contentData.about ?? ""
            retval.picture = contentData.picture ?? ""
            retval.lud06 = contentData.lud06 ?? ""
            retval.lud16 = contentData.lud16 ?? ""
            retval.nip05 = contentData.nip05 ?? ""
        }
        return retval
    }
    
    struct MetaDataContentData: Codable {
        var name: String?
        var about: String?
        var picture: String?
        var nip05: String?
        var lud06: String?
        var lud16: String?
        var display_name: String?
        var website: String?
    }
    
    static let preview = PublicKeyMetaData(value: [
        "publicKey": "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778",
        "name": "ismyhc",
        "about": "Founder and CEO at Galaxoid Labs. Working on lots of cool stuff around Bitcoin.",
        "picture": "https://fiatjaf.com/static/favicon.jpg",
        "nip05": "ismyhc@galaxoidlabs.com",
        "lud06": "lnurl1dp68gurn8ghj7ctsdyh85etzv4jx2efwd9hj7a3s9aex2ut4v4ehgttnw3shg6tr943ksctjvajhxte4v4nxve3kvdnz6cfe893z6drxvgcz6c34vcez6wfsxsmxgvecvsukgceevgt8jy",
        "lud16": "ismyhc@zbd.gg",
        "website": "https://galaxoidlabs.com",
        "displayName": "Jacob Davis",
        "createdAt": Date(),
    ])
    
    @MainActor
    func updateNip05Verified() async {
        
        guard let url = nip05Url else {
            return
        }
        
        guard let namePart = nip05Components?.first else {
            return
        }
        
        let urlRequest = URLRequest(url: url)
        if let res = try? await URLSession.shared.data(for: urlRequest) {
            DispatchQueue.main.async {
                let decoder = JSONDecoder()
                if let info = try? decoder.decode(Nip05Response.self, from: res.0) {
                    Task {
                        if let thawed = self.thaw() {
                            do {
                                try await Realm().writeAsync {
                                    thawed.nip05Verified = (info.names?[namePart] == self.publicKey)
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                } else {
                    print("Unable to decode relay information")
                }
            }
        }
    }
    
    struct Nip05Response: Codable {
        let names: [String: String]?
        let relays: [String: [String]]?
    }
    
}
