//
//  EventMessage.swift
//  Seer
//
//  Created by Jacob Davis on 6/12/24.
//

import Foundation
import SwiftData
import Nostr

@Model final class EventMessage {
    
    @Attribute(.unique) let id: String
    var relayUrl: String
    var publicKey: String
    var createdAt: Date
    var groupId: String
    var content: String?
    
    init(id: String, relayUrl: String, publicKey: String, createdAt: Date, groupId: String, content: String? = nil) {
        self.id = id
        self.relayUrl = relayUrl
        self.publicKey = publicKey
        self.createdAt = createdAt
        self.groupId = groupId
        self.content = content
    }
    
    var contentFormatted: AttributedString? {
        var attr = try? AttributedString(markdown: content ?? "",
                                         options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        if let runs = attr?.runs {
            for run in runs {
                if run.link != nil {
                    attr?[run.range].underlineStyle = .single
                    attr?[run.range].foregroundColor = .mint
                }
            }
        }
        return attr
    }
    
}

extension EventMessage {
    static func create(from event: Event, relayUrl: String) -> EventMessage? {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "h" })?.otherInformation.first else { return nil }
        guard let id = event.id else { return nil }
        return EventMessage(id: id, relayUrl: relayUrl, publicKey: event.pubkey, createdAt: event.createdAt.date, groupId: groupId, content: event.content)
    }
}
