//
//  DBEvent.swift
//  Seer
//
//  Created by Jacob Davis on 7/29/24.
//

import Foundation
import Nostr
import SwiftData

let kindGroupChatMessage = Int(Kind.groupChatMessage.id)
let kindGroupChatMessageReply = Int(Kind.groupChatMessageReply.id)
let kindGroupForumMessage = Int(Kind.groupForumMessage.id)
let kindGroupForumMessageReply = Int(Kind.groupForumMessageReply.id)
let kindGroupMetadata = Int(Kind.groupMetadata.id)
let kindGroupMembers = Int(Kind.groupMembers.id)
let kindGroupAdmins = Int(Kind.groupAdmins.id)
let kindGroupList = Int(Kind.groupList.id)
let kindSetMetdata = Int(Kind.setMetadata.id)

@Model
final public class DBEvent {
    
    @Attribute(.unique) public let id: String // 32-byte lowercase hex-encoded sha256 of the serialized event data
    public let pubkey: String // 32-byte lowercase hex-encoded public key of the event creator
    public let createdAt: Date // Unix timestamp in seconds
    public let kind: Int // Integer between 0 and 65535 // Note: This should be UInt16, but swift data has some bug where predicates wont compare on UInt16
    public let tags: [Tag] // Array of arrays of strings for tags
    public let content: String // Arbitrary string content
    public let sig: String // 64-byte lowercase hex of the signature
    public let relayUrl: String
    public let serializedTags: String // This is used for queries
    
    public init(id: String, pubkey: String, createdAt: Date, kind: Int, tags: [Tag], content: String,
                sig: String, relayUrl: String) {
        self.id = id
        self.pubkey = pubkey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.sig = sig
        self.relayUrl = relayUrl
        self.serializedTags = Self.serializeTags(tags)
    }
    
    public init?(event: Event, relayUrl: String) {
        guard let id = event.id else { return nil }
        guard let sig = event.sig else { return nil }
        self.id = id
        self.pubkey = event.pubkey
        self.createdAt = event.createdAt.date
        self.kind = Int(event.kind.id)
        self.tags = event.tags
        self.content = event.content
        self.sig = sig
        self.relayUrl = relayUrl
        self.serializedTags = Self.serializeTags(event.tags)
    }
    
    public static let tagDelimiter = "•:t;•"
    public static let infoDelimiter = "•:i;•"
    
    private static func serializeTags(_ tags: [Tag]) -> String {
        return tags.map { tag in
            let infoString = tag.otherInformation.joined(separator: infoDelimiter)
            return "\(tag.id)\(infoDelimiter)\(infoString)"
        }.joined(separator: tagDelimiter)
    }
}
