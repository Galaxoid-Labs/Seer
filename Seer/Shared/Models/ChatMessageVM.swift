//
//  ChatMessageVM.swift
//  Seer
//
//  Created by Jacob Davis on 7/31/24.
//

import Foundation
import SwiftData
import Nostr

struct ChatMessageVM: Identifiable, Hashable {
    
    let id: String
    let kind: Int
    let publicKey: String
    let createdAt: Date
    let groupId: String
    let content: String
    let contentFormated: AttributedString
    let imageUrls: [URL]
    let videoUrls: [URL]
    let urls: [String: [URL]]
    
    var rootEventId: String?
    var replyToEventId: String?

    init(id: String, kind: Int, publicKey: String, createdAt: Date, groupId: String, content: String,
         contentFormated: AttributedString, imageUrls: [URL], videoUrls: [URL], urls: [String: [URL]], 
         rootEventId: String? = nil, replyToEventId: String? = nil) {
        self.id = id
        self.kind = kind
        self.publicKey = publicKey
        self.createdAt = createdAt
        self.groupId = groupId
        self.content = content
        self.contentFormated = contentFormated
        self.imageUrls = imageUrls
        self.videoUrls = videoUrls
        self.urls = urls
        self.rootEventId = rootEventId
        self.replyToEventId = replyToEventId
    }
    
    init?(event: DBEvent) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "h" })?.otherInformation.first else { return nil }
        
        self.id = event.id
        self.kind = event.kind
        self.publicKey = event.pubkey
        self.createdAt = event.createdAt
        self.groupId = groupId
        self.content = event.content
        
        let contentFormated = ChatMessageVM.format(content: content) ?? ""
        
        self.contentFormated = contentFormated
        self.imageUrls = contentFormated.runs.compactMap({
            if let link = $0.link, link.isImageType() {
                return link.absoluteURL
            }
            return nil
        })
        self.videoUrls = contentFormated.runs.compactMap({
            if let link = $0.link, link.isVideoType() {
                return link.absoluteURL
            }
            return nil
        })

        let other = contentFormated.runs.compactMap({
            if let link = $0.link, !link.isImageType() && !link.isVideoType() {
                return link.absoluteURL
            }
            return nil
        })
        
        self.urls = [
            "videos": self.videoUrls,
            "images": self.imageUrls,
            "links": other
        ]
        
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
    
}
