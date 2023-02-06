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
                            .badge(ownerKey.getTotalUnreadCount())
                    }
                    NavigationLink(value: Navigation.SidebarValue(filter: "unknown", ownerKey: ownerKey)) {
                        Label("Unknown", systemImage: "questionmark.bubble")
                    }
                    NavigationLink(value: Navigation.SidebarValue(filter: "hidden", ownerKey: ownerKey)) {
                        Label("Hidden", systemImage: "eye.slash")
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: "key.fill")
                            .imageScale(.large)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .opacity(0.1)
                            )
                            .padding(4)
                        VStack(alignment: .leading) {
                            if let name = ownerKey.publicKeyMetaData?.name, !name.isEmpty {
                                Text(name)
                                    .bold()
                                    .foregroundColor(.secondary)
                            }
                            Text(ownerKey.bech32PublicKey ?? "")
                        }
                    }
                    .truncationMode(.middle)
                    .padding(.trailing, 8)
                }
            }
        }
        .navigationSplitViewColumnWidth(250)
        
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
    }
}
