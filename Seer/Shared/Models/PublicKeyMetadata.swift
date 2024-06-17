//
//  PublicKeyMetadata.swift
//  Seer
//
//  Created by Jacob Davis on 4/8/24.
//

import Foundation
import SwiftData
import Nostr

@Model final class PublicKeyMetadata {
    
    @Attribute(.unique) let publicKey: String
    let bech32PublicKey: String?
    
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var lud06: String?
    var lud16: String?
    var createdAt: Date
    var nip05Verified: Bool
    
    init(publicKey: String, bech32PublicKey: String? = nil, name: String? = nil, about: String? = nil, picture: String? = nil,
         nip05: String? = nil, lud06: String? = nil, lud16: String? = nil, createdAt: Date, nip05Verified: Bool) {
        self.publicKey = publicKey
        self.bech32PublicKey = try? publicKey.bech32FromHex(hrp: "npub")
        self.name = name
        self.about = about
        self.picture = picture
        self.nip05 = nip05
        self.lud06 = lud06
        self.lud16 = lud16
        self.createdAt = createdAt
        self.nip05Verified = nip05Verified
    }
    
    var nip05Components: [String]? {
        if let nip05, !nip05.isEmpty {
            return nip05.components(separatedBy: "@")
        }
        return nil
    }
    
    var legitNipO5: Bool {
        if let nip05Components {
            return nip05Components.count == 2 // TODO: Better check here...
        }
        return false
    }
    
    var nip05Url: URL? {
        guard let nip05Components else { return nil }
        if nip05Components.count != 2 {
            return nil
        }
        return URL(string: "https://\(nip05Components[1])/.well-known/nostr.json?name=\(nip05Components[0])")
    }
    
    var bestPublicName: String {
        if legitNipO5 {
            return nip05!
        } else if let name, !name.isEmpty {
            return name
        } else if let bech32PublicKey {
            return bech32PublicKey
        }
        return publicKey
    }

}

extension PublicKeyMetadata {
    
    static func create(from event: Event) -> PublicKeyMetadata? {
        
        let publicKeyMetadata = PublicKeyMetadata(publicKey: event.pubkey, createdAt: event.createdAt.date, nip05Verified: false)
        
        let decoder = JSONDecoder()
        if let contentData = try? decoder.decode(MetadataContentData.self, from: Data(event.content.utf8)) {
            publicKeyMetadata.name = contentData.name ?? ""
            publicKeyMetadata.about = contentData.about ?? ""
            publicKeyMetadata.picture = contentData.picture ?? ""
            publicKeyMetadata.lud06 = contentData.lud06 ?? ""
            publicKeyMetadata.lud16 = contentData.lud16 ?? ""
            publicKeyMetadata.nip05 = contentData.nip05 ?? ""
        }

        return publicKeyMetadata
    }
    
}

struct MetadataContentData: Codable {
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var lud06: String?
    var lud16: String?
    var display_name: String?
    var website: String?
}
