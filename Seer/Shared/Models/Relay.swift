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
    var icon: String
    
    init(url: String, name: String = "", desc: String = "", publicKey: String = "", contact: String = "", supportedNips: Set<Int> = [],
         software: String = "", version: String = "", updatedAt: Date = .now, metadataOnly: Bool = false, icon: String = "") {
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
        self.icon = icon
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
    
    func updateRelayInfo() async -> Void {
        if let relayInfo = await NostrClient.fetchRelayInfo(relayUrl: url) {
            self.name = relayInfo.info.name ?? self.name
            self.desc = relayInfo.info.description ?? self.desc
            self.publicKey = relayInfo.info.publicKey ?? self.publicKey
            self.contact = relayInfo.info.contact ?? self.contact
            self.supportedNips = Set(relayInfo.info.supportedNips)
            if self.supportedNips.contains(29) {
                self.metadataOnly = true
            } else {
                self.metadataOnly = false
            }
            self.software = relayInfo.info.software ?? self.software
            self.version = relayInfo.info.version ?? self.version
            self.icon = relayInfo.info.icon ?? self.icon
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
