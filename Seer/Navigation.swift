//
//  Navigation.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import Foundation
import SwiftUI

class Navigation: ObservableObject {
    
    #if os(macOS)
    
    @Published var sidebarValue: SidebarValue = SidebarValue(filter: "", ownerKey: nil)
    @Published var contentValue: ContentValue = ContentValue(publicKeyMetaData: nil, ownerKey: nil)
    
    struct SidebarValue: Hashable {
        let filter: String
        let ownerKey: OwnerKey?
    }
    
    struct ContentValue: Hashable {
        let publicKeyMetaData: PublicKeyMetaData?
        let ownerKey: OwnerKey?
    }

    #endif
    
}
