//
//  DBEvent.swift
//  Seer
//
//  Created by Jacob Davis on 7/29/24.
//

import Foundation
import Nostr
import SwiftData

@Model
public class DBEvent {
    @Attribute(.unique)
    public var id: String // 32-byte lowercase hex-encoded sha256 of the serialized event data
    
    public var pubkey: String // 32-byte lowercase hex-encoded public key of the event creator
    public var createdAt: Timestamp // Unix timestamp in seconds
    public var kind: Kind // Integer between 0 and 65535
    public var tags: [Tag] // Array of arrays of strings for tags
    public var content: String // Arbitrary string content
    public var sig: String // 64-byte lowercase hex of the signature
    public var relayUrl: String
    
    public init(id: String, pubkey: String, createdAt: Timestamp, kind: Kind, tags: [Tag], content: String, sig: String, relayUrl: String) {
        self.id = id
        self.pubkey = pubkey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.sig = sig
        self.relayUrl = relayUrl
    }
    
    public init?(event: Event, relayUrl: String) {
        guard let id = event.id else { return nil }
        guard let sig = event.sig else { return nil }
        self.id = id
        self.pubkey = event.pubkey
        self.createdAt = event.createdAt
        self.kind = event.kind
        self.tags = event.tags
        self.content = event.content
        self.sig = sig
        self.relayUrl = relayUrl
    }
}
