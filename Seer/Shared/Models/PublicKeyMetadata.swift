//
//  PublicKeyMetadata.swift
//  Seer
//
//  Created by Jacob Davis on 8/21/24.
//

import Foundation
import SwiftData
import Nostr

@Model
final class PublicKeyMetadata {
   
    @Attribute(.unique) var publicKey: String
    var bech32PublicKey: String
    
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var lud06: String?
    var lud16: String?
    var createdAt: Date
    var nip05Verified: Bool
    
    init(publicKey: String, bech32PublicKey: String, name: String?, about: String?, picture: String?, nip05: String?, lud06: String?, lud16: String?, createdAt: Date, nip05Verified: Bool) {
        self.publicKey = publicKey
        self.bech32PublicKey = bech32PublicKey
        self.name = name
        self.about = about
        self.picture = picture
        self.nip05 = nip05
        self.lud06 = lud06
        self.lud16 = lud16
        self.createdAt = createdAt
        self.nip05Verified = nip05Verified
    }
    
    init?(event: Event) {
        guard let bech32PublicKey = try? event.pubkey.bech32FromHex(hrp: "npub") else { return nil }
        self.publicKey = event.pubkey
        self.bech32PublicKey = bech32PublicKey
        
        let contentData = try? JSONDecoder().decode(MetadataContentData.self, from: Data(event.content.utf8))
        self.name = contentData?.name ?? ""
        self.about = contentData?.about ?? ""
        self.picture = contentData?.picture ?? ""
        self.lud06 = contentData?.lud06 ?? ""
        self.lud16 = contentData?.lud16 ?? ""
        self.nip05 = contentData?.nip05 ?? ""
        
        self.createdAt = event.createdAt.date
        self.nip05Verified = false // TODO: Fetch this.
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
        }
        return bech32PublicKey
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

extension PublicKeyMetadata: Hashable, Identifiable {
    var id: String { return publicKey }
}
