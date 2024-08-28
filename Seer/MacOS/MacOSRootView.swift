//
//  MacOSRootView.swift
//  Seer
//
//  Created by Jacob Davis on 3/26/24.
//
#if os(macOS)
import SwiftUI
import SwiftData
import Nostr

struct MacOSRootView: View {
    
    @EnvironmentObject var appState: AppState

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @Query private var ownerAccounts: [OwnerAccount]
    @Query private var publicKeyMetadata: [PublicKeyMetadata]

    var body: some View {
        ZStack {
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                MacOSSidebarView(columnVisibility: $columnVisibility)
                    .frame(minWidth: 275)
            } content: {
                MacOSGroupListView(relayUrl: appState.selectedRelay?.url ?? "")
                    .frame(minWidth: 300)
                    .navigationTitle("Groups")
                    .navigationSubtitle("")
            } detail: {
                MacOSMessageDetailView(relayUrl: appState.selectedRelay?.url ?? "", groupId: appState.selectedGroup?.id ?? "", chatMessageNumResults: $appState.chatMessageNumResults)
                    .frame(minWidth: 500)
            }
            
        }
        .sheet(isPresented: $appState.showOnboarding) {
            MacOSStartView()
                .frame(width: 400, height: 500)
        }
        .onAppear {
            if ownerAccounts.isEmpty {
                appState.showOnboarding = true
            }
        }
    }
}

#Preview {
    MacOSRootView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
        .frame(minWidth: 1000)
}
#endif
