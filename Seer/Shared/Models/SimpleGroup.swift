//
//  SimpleGroup.swift
//  Seer
//
//  Created by Jacob Davis on 4/18/24.
//

import Foundation
import SwiftData
import Nostr

@Model final class SimpleGroup {
    
    @Attribute(.unique) let id: String
    var relayUrl: String
    var name: String?
    var picture: String?
    var about: String?
    var isPublic: Bool
    var isOpen: Bool
    
//    ["d", "<group-id>"],
//    ["name", "Pizza Lovers"],
//    ["picture", "https://pizza.com/pizza.png"],
//    ["about", "a group for people who love pizza"],
//    ["public"], // or ["private"]
//    ["open"] // or ["closed"]
    
    init(id: String, relayUrl: String, name: String? = nil, picture: String? = nil, about: String? = nil, isPublic: Bool, isOpen: Bool) {
        self.id = id
        self.relayUrl = relayUrl
        self.name = name
        self.picture = picture
        self.about = about
        self.isPublic = isPublic
        self.isOpen = isOpen
    }
}

extension SimpleGroup {
    static func create(from event: Event, relayUrl: String) -> SimpleGroup? {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return nil }
        print(groupId)
        let isPublic = tags.first(where: { $0.id == "private"}) == nil
        let isOpen = tags.first(where: { $0.id == "closed" }) == nil
        let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
        let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
        let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
        return SimpleGroup(id: groupId, relayUrl: relayUrl, name: name, about: about, isPublic: isPublic, isOpen: isOpen)
    }
}
