//
//  ChatMessage.swift
//  Seer
//
//  Created by Jacob Davis on 8/21/24.
//

import Foundation
import SwiftData
import Nostr

@Model
final class ChatMessage: Identifiable, Hashable {
    
    @Attribute(.unique) var id: String
    var kind: Int
    var publicKey: String
    var createdAt: Date
    var groupId: String
    var content: String
    var imageUrls: [URL]
    var videoUrls: [URL]
    var urls: [String: [URL]]
    var relayUrl: String
    
    var rootEventId: String?
    var replyToEventId: String?
    
    @Relationship(deleteRule: .nullify) var rootChatMessage: ChatMessage?
    @Relationship(deleteRule: .nullify) var replyToChatMessage: ChatMessage?
    @Relationship(deleteRule: .nullify) var publicKeyMetadata: PublicKeyMetadata?
    
    @Transient @Cached
    var contentFormated: AttributedString?

    init(id: String, kind: Int, publicKey: String, createdAt: Date, groupId: String, content: String,
         imageUrls: [URL], videoUrls: [URL], urls: [String: [URL]],
         relayUrl: String, rootEventId: String? = nil, replyToEventId: String? = nil, publicKeyMetadata: PublicKeyMetadata? = nil,
         rootChatMessage: ChatMessage? = nil, replyToChatMessage: ChatMessage? = nil) {
        self.id = id
        self.kind = kind
        self.publicKey = publicKey
        self.createdAt = createdAt
        self.groupId = groupId
        self.content = content
        self.imageUrls = imageUrls
        self.videoUrls = videoUrls
        self.urls = urls
        self.relayUrl = relayUrl
        self.rootEventId = rootEventId
        self.replyToEventId = replyToEventId
        self.publicKeyMetadata = publicKeyMetadata
        self.rootChatMessage = rootChatMessage
        self.replyToChatMessage = replyToChatMessage
        self.contentFormated = ChatMessage.format(content: content)
    }
    
    init?(event: Event, relayUrl: String) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "h" })?.otherInformation.first else { return nil }
        guard let id = event.id else { return nil }
        
        self.id = id
        self.kind = Int(event.kind.id)
        self.publicKey = event.pubkey
        self.createdAt = event.createdAt.date
        self.groupId = groupId
        self.content = event.content
        
        let contentFormated = ChatMessage.format(content: event.content) ?? ""
        
        //self.contentFormated = contentFormated
        let imageUrls = contentFormated.runs.compactMap({
            if let link = $0.link, link.isImageType() {
                return link.absoluteURL
            }
            return nil
        })
        self.imageUrls = imageUrls
        
        let videoUrls = contentFormated.runs.compactMap({
            if let link = $0.link, link.isVideoType() {
                return link.absoluteURL
            }
            return nil
        })
        self.videoUrls = videoUrls

        let other = contentFormated.runs.compactMap({
            if let link = $0.link, !link.isImageType() && !link.isVideoType() {
                return link.absoluteURL
            }
            return nil
        })
        
        self.urls = [
            "videos": videoUrls,
            "images": imageUrls,
            "links": other
        ]
        
        self.relayUrl = relayUrl
        
        if let reply = tags.first(where: { $0.id == "e" && $0.otherInformation.contains("reply") })?.otherInformation {
            if let eventId = reply.first, eventId != "" {
                self.replyToEventId = eventId
            }
        }
        
        if let root = tags.first(where: { $0.id == "e" && $0.otherInformation.contains("root") })?.otherInformation {
            if let eventId = root.first, eventId != "" {
                self.rootEventId = eventId
                // We set replyToEventId to root if there isnt a reply.
                if self.replyToEventId == nil {
                    self.replyToEventId = eventId
                }
            }
        }
        
    }
    
    func formatedContent() -> AttributedString? {
        self.contentFormated = ChatMessage.format(content: self.content)
        return self.contentFormated
    }
    
    private static func format(content: String) -> AttributedString? {
        var attr = try? AttributedString(markdown: content,
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
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id && lhs.relayUrl == rhs.relayUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(relayUrl)
    }
    
}

extension ChatMessage {
    static func predicate(byGroupId groupId: String, relayUrl: String) -> Predicate<ChatMessage> {
        return #Predicate<ChatMessage> { $0.groupId == groupId && $0.relayUrl == relayUrl }
    }
    
    static func predicate(relayUrl: String) -> Predicate<ChatMessage> {
        return #Predicate<ChatMessage> { $0.relayUrl == relayUrl }
    }
}


@propertyWrapper
struct Cached<T> {
    private var storage: T?
    private let generator: () -> T

    init(wrappedValue: @autoclosure @escaping () -> T) {
        self.generator = wrappedValue
    }

    var wrappedValue: T {
        mutating get {
            if let value = storage {
                return value
            }
            let value = generator()
            storage = value
            return value
        }
        set {
            storage = newValue
        }
    }
}

