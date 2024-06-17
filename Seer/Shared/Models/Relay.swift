//
//  Relay.swift
//  Seer
//
//  Created by Jacob Davis on 4/16/24.
//

import Foundation
import SwiftData
import NostrClient

@Model final class Relay: Identifiable {
    
    struct RelayInformation: Codable {
        var name: String?
        var description: String?
        var pubkey: String?
        var contact: String?
        var supported_nips: [Int]?
        var software: String?
        var version: String?
    }
    
    @Attribute(.unique) let url: String
    var name: String
    var desc: String
    var publicKey: String
    var contact: String
    var supportedNips: Set<Int>
    var software: String
    var version: String
    var updatedAt: Date
    var metadataOnly: Bool
    
    init(url: String, name: String = "", desc: String = "", publicKey: String = "", contact: String = "", supportedNips: Set<Int> = [],
         software: String = "", version: String = "", updatedAt: Date = .now, metadataOnly: Bool = false) {
        self.url = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.name = name
        self.desc = desc
        self.publicKey = publicKey
        self.contact = contact
        self.supportedNips = supportedNips
        self.software = software
        self.version = version
        self.updatedAt = updatedAt
        self.metadataOnly = metadataOnly
    }
    
    var httpUrl: URL? {
        let httpUrlString = url
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")
        return URL(string: httpUrlString)
    }
    
    func nip29Support() -> Bool {
        return supportedNips.contains(29)
    }
    
    func fetchRelayInfo() async -> (url: String, info: RelayInformation)? {
        guard let httpUrl else {
            return nil
        }
        
        var urlRequest = URLRequest(url: httpUrl)
        urlRequest.setValue("application/nostr+json", forHTTPHeaderField: "Accept")
        
        if let res = try? await URLSession.shared.data(for: urlRequest) {
            let decoder = JSONDecoder()
            let info = try? decoder.decode(RelayInformation.self, from: res.0)
            return (url: self.url, info: info) as? (url: String, info: Relay.RelayInformation)
        }
        
        return nil
    }
    
    func updateRelayInfo() async -> Void {
        let relayInfo = await self.fetchRelayInfo()
        if let relayInfo {
            self.name = relayInfo.info.name ?? self.name
            self.desc = relayInfo.info.description ?? self.desc
            self.publicKey = relayInfo.info.pubkey ?? self.publicKey
            self.contact = relayInfo.info.contact ?? self.contact
            if let nips = relayInfo.info.supported_nips {
                self.supportedNips = Set(nips)
                if !nips.contains(29) {
                    self.metadataOnly = true
                } else {
                    self.metadataOnly = false
                }
            }
            self.software = relayInfo.info.software ?? self.software
            self.version = relayInfo.info.version ?? self.version
        }
    }

}

extension Relay {
    
    static func createNew(withUrl url: String) -> Relay? {
        if url.hasPrefix("wss://") || url.hasPrefix("ws://") {
            return Relay(url: url)
        }
        return nil
    }
    
}
