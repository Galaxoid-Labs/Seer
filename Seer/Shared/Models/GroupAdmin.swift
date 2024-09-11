//
//  GroupAdmin.swift
//  Seer
//
//  Created by Jacob Davis on 8/21/24.
//

import Foundation
import SwiftData
import Nostr

@Model
final class GroupAdmin: Hashable, Identifiable {
    
    enum Capability: String, CaseIterable, Codable {
        case AddUser = "add-user"
        case EditMetadata = "edit-metadata"
        case DeleteEvent = "delete-event"
        case RemoveUser = "remove-user"
        case AddPermission = "add-permission"
        case RemovePermission = "remove-permission"
        case EditGroupStatus = "edit-group-status"
    }
    
    @Attribute(.unique) var id: String
    
    var publicKey: String
    var groupId: String
    var capabilities: Set<Capability>
    var relayUrl: String
    @Relationship(deleteRule: .nullify) var publicKeyMetadata: PublicKeyMetadata?
    
    init(publicKey: String, groupId: String, capabilities: Set<Capability>, relayUrl: String, publicKeyMetadata: PublicKeyMetadata? = nil) {
        self.id = publicKey + ":a:" + groupId
        self.publicKey = publicKey
        self.groupId = groupId
        self.capabilities = capabilities
        self.relayUrl = relayUrl
        self.publicKeyMetadata = publicKeyMetadata
    }
    
    init?(publicKey: String?, groupId: String, capabilities: [String], relayUrl: String, publicKeyMetadata: PublicKeyMetadata? = nil) {
        guard let publicKey else { return nil }
        self.id = publicKey + ":a:" + groupId
        self.publicKey = publicKey
        self.groupId = groupId
        self.capabilities = Set(capabilities.compactMap({ Capability(rawValue: $0) }))
        self.relayUrl = relayUrl
        self.publicKeyMetadata = publicKeyMetadata
    }
    
    static func == (lhs: GroupAdmin, rhs: GroupAdmin) -> Bool {
        return lhs.id == rhs.id && lhs.capabilities == rhs.capabilities && lhs.relayUrl == rhs.relayUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(capabilities)
        hasher.combine(relayUrl)
    }
    
}

extension GroupAdmin {
    static func predicate(byGroupId groupId: String, relayUrl: String) -> Predicate<GroupAdmin> {
        return #Predicate<GroupAdmin> { $0.groupId == groupId && $0.relayUrl == relayUrl }
    }
}
