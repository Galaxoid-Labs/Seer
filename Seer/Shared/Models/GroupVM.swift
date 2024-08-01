//
//  GroupVM.swift
//  Seer
//
//  Created by Jacob Davis on 7/30/24.
//

import Foundation
import SwiftData
import Nostr

struct GroupVM: Hashable, Identifiable {
    
    let id: String
    var relayUrl: String
    var name: String?
    var picture: String?
    var about: String?
    var isPublic: Bool
    var isOpen: Bool
    
    init(id: String, relayUrl: String, name: String? = nil, picture: String? = nil, about: String? = nil, 
         isPublic: Bool, isOpen: Bool) {
        self.id = id
        self.relayUrl = relayUrl
        self.name = name
        self.picture = picture
        self.about = about
        self.isPublic = isPublic
        self.isOpen = isOpen
    }
    
    init?(event: DBEvent) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return nil }
        let isPublic = tags.first(where: { $0.id == "private"}) == nil
        let isOpen = tags.first(where: { $0.id == "closed" }) == nil
        let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
        let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
        let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
        
        self.id = groupId
        self.relayUrl = event.relayUrl
        self.name = name
        self.picture = picture
        self.about = about
        self.isPublic = isPublic
        self.isOpen = isOpen
    }
}
