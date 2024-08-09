//
//  GroupAdminVM.swift
//  Seer
//
//  Created by Jacob Davis on 8/6/24.
//

import Foundation
import SwiftData
import Nostr

struct GroupAdminVM: Hashable, Identifiable {
    
    enum Capability: String, CaseIterable {
        case AddUser = "add-user"
        case EditMetadata = "edit-metadata"
        case DeleteEvent = "delete-event"
        case RemoveUser = "remove-user"
        case AddPermission = "add-permission"
        case RemovePermission = "remove-permission"
        case EditGroupStatus = "edit-group-status"
    }
    
    var id: String {
        return publicKey + ":a:" + groupId
    }
    
    let publicKey: String
    let groupId: String
    let capabilities: Set<Capability>
    var metadata: PublicKeyMetadataVM?
    
    init(publicKey: String, groupId: String, capabilities: Set<Capability>, metadata: PublicKeyMetadataVM? = nil) {
        self.publicKey = publicKey
        self.groupId = groupId
        self.capabilities = capabilities
        self.metadata = metadata
    }
    
    init?(publicKey: String?, groupId: String, capabilities: [String], metadata: PublicKeyMetadataVM? = nil) {
        guard let publicKey else { return nil }
        self.publicKey = publicKey
        self.groupId = groupId
        self.capabilities = Set(capabilities.compactMap({ Capability(rawValue: $0) }))
        self.metadata = metadata
    }
    
}
