//
//  GroupMember.swift
//  Seer
//
//  Created by Jacob Davis on 8/21/24.
//

import Foundation
import SwiftData
import Nostr

@Model
final class GroupMember: Hashable, Identifiable {
    
    @Attribute(.unique) var id: String
    
    var publicKey: String
    var groupId: String
    var relayUrl: String
    @Relationship(deleteRule: .nullify) var publicKeyMetadata: PublicKeyMetadata?
    
    init(publicKey: String, groupId: String, relayUrl: String, publicKeyMetadata: PublicKeyMetadata? = nil) {
        self.id = publicKey + ":m:" + groupId
        self.publicKey = publicKey
        self.groupId = groupId
        self.relayUrl = relayUrl
        self.publicKeyMetadata = publicKeyMetadata
    }
    
    static func == (lhs: GroupMember, rhs: GroupMember) -> Bool {
        return lhs.id == rhs.id && lhs.relayUrl == rhs.relayUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(relayUrl)
    }
    
}

extension GroupMember {
    static func predicate(byGroupId groupId: String, relayUrl: String) -> Predicate<GroupMember> {
        return #Predicate<GroupMember> { $0.groupId == groupId && $0.relayUrl == relayUrl }
    }
}
