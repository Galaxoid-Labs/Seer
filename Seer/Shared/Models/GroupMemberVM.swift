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
        return publicKey + ":" + groupId
    }
    
    let publicKey: String
    let groupId: String
    
    init(publicKey: String, groupId: String) {
        self.publicKey = publicKey
        self.groupId = groupId
    }
    
    init?(event: DBEvent) {
        let tags = event.tags.map({ $0 })
        guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return nil }
        
        let pp = tags.filter({ $0.id == "p" }).first?.otherInformation.last
        print(pp)
        
        guard let pk = tags.filter({ $0.id == "p" }).first?.otherInformation.last else { return nil }
        self.publicKey = pk
        self.groupId = groupId
    }
}
