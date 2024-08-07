//
//  GroupMemberVM.swift
//  Seer
//
//  Created by Jacob Davis on 8/6/24.
//

import Foundation
import SwiftData
import Nostr

struct GroupMemberVM: Hashable, Identifiable {
    
    var id: String {
        return publicKey + ":m:" + groupId
    }
    
    let publicKey: String
    let groupId: String
    
    init(publicKey: String, groupId: String) {
        self.publicKey = publicKey
        self.groupId = groupId
    }
    
}
