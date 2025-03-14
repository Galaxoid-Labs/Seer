//
//  Group.swift
//  Seer
//
//  Created by Jacob Davis on 8/21/24.
//

import Foundation
import SwiftData
import Nostr

@Model
final class Group: Hashable, Identifiable {
    
    @Attribute(.unique) var id: String
    var relayUrl: String
    var name: String?
    var picture: String?
    var about: String?
    var isPublic: Bool
    var isOpen: Bool
    var isMember: Bool
    var isAdmin: Bool
    
    init(id: String, relayUrl: String, name: String? = nil, picture: String? = nil, about: String? = nil,
         isPublic: Bool, isOpen: Bool, isMember: Bool, isAdmin: Bool) {
        self.id = id
        self.relayUrl = relayUrl
        self.name = name
        self.picture = picture
        self.about = about
        self.isPublic = isPublic
        self.isOpen = isOpen
        self.isMember = isMember
        self.isAdmin = isAdmin
    }
    
    init?(event: Event, relayUrl: String) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return nil }
        let isPublic = tags.first(where: { $0.id == "private"}) == nil
        let isOpen = tags.first(where: { $0.id == "closed" }) == nil
        let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
        let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
        let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
        
        self.id = groupId
        self.relayUrl = relayUrl
        self.name = name
        self.picture = picture
        self.about = about
        self.isPublic = isPublic
        self.isOpen = isOpen
        self.isMember = false
        self.isAdmin = false
    }
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id && lhs.relayUrl == rhs.relayUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(relayUrl)
    }
}

extension Group {
    static func predicate(relayUrl: String, isMember: Bool) -> Predicate<Group> {
        if isMember {
            return #Predicate<Group> { $0.relayUrl == relayUrl && $0.name != nil && $0.isMember }
        }
        return #Predicate<Group> {
            $0.relayUrl == relayUrl && $0.name != nil && $0.isPublic && $0.isOpen && !$0.isMember && !$0.isAdmin
        }
    }
}
