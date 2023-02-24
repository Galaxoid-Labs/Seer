//
//  SidebarView.swift
//  Seer
//
//  Created by Jacob Davis on 2/6/23.
//

import SwiftUI
import RealmSwift
import KeychainAccess

struct SidebarView: View {
    
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var appState: AppState
    
    @ObservedResults(OwnerKey.self) var ownerKeys
    
    var body: some View {
        List(selection: $navigation.sidebarValue) {
            ForEach(ownerKeys) { ownerKey in
                Section {
                    NavigationLink(value: Navigation.SidebarValue(filter: "inbox", ownerKey: ownerKey)) {
                        Label("Inbox", systemImage: "bubble.left")
                            .badge(ownerKey.getInboxUnreadCount())
                    }
                    NavigationLink(value: Navigation.SidebarValue(filter: "unknown", ownerKey: ownerKey)) {
                        Label("Unknown", systemImage: "questionmark.bubble")
                            .badge(ownerKey.getUknownUnreadCount())
                    }
                    NavigationLink(value: Navigation.SidebarValue(filter: "hidden", ownerKey: ownerKey)) {
                        Label("Hidden", systemImage: "eye.slash")
                    }
                } header: {
                    Text(ownerKey.bestPublicName)
                        .truncationMode(.middle)
                        .padding(.trailing, 8)
                }
            }
        }
        .navigationSplitViewColumnWidth(250)
        .onChange(of: navigation.sidebarValue) { newValue in
            navigation.contentValue = Navigation.ContentValue(publicKeyMetaData: nil, ownerKey: newValue.ownerKey)
        }
        
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
    }
}
