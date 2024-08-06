//
//  GroupMemberAdminVM.swift
//  Seer
//
//  Created by Jacob Davis on 8/6/24.
//

import Foundation
import SwiftData
import Nostr

struct GroupMemberAdminVM: Hashable, Identifiable {
    
    enum Capability: String {
        case AddUser = "add-user"
        case EditMetada = "edit-metadata"
        case DeleteEvent = "delete-event"
        case RemoveUser = "remove-user"
        case AddPermission = "add-permission"
        case RemovePermission = "remove-permission"
        case EditGroupStatus = "edit-group-status"
    }
    
    var id: String {
        return publicKey + ":" + groupId
    }
    
    let publicKey: String
    let groupId: String
    let capabilities: Set<Capability>
    
    init(publicKey: String, groupId: String, capabilities: Set<Capability>) {
        self.publicKey = publicKey
        self.groupId = groupId
        self.capabilities = capabilities
    }
    
    init?(event: DBEvent) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return nil }
        self.publicKey = event.pubkey
        self.groupId = groupId
        
        // get capabilities from tags
        
        self.capabilities = []
    }
}
