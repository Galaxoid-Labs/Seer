//
//  MacOSRootView.swift
//  Seer
//
//  Created by Jacob Davis on 3/26/24.
//
#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSRootView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedGroup: SimpleGroup?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @Query private var ownerAccounts: [OwnerAccount]
    @Query private var simpleGroups: [SimpleGroup]
    var groups: [SimpleGroup] {
        return simpleGroups.filter({ $0.relayUrl == appState.selectedRelay?.url ?? ""})
    }
    
    @Query private var eventMessages: [EventMessage]
    var messages: [EventMessage] {
        return eventMessages
                    .filter({ $0.groupId == selectedGroup?.id ?? ""})
                    .sorted(by: { $0.createdAt < $1.createdAt })
    }
    

    var body: some View {
        ZStack {
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                MacOSSidebarView(columnVisibility: $columnVisibility)
                    .frame(minWidth: 275)
            } content: {
                MacOSGroupListView(selectedGroup: $selectedGroup, groups: groups, eventMessages: eventMessages)
                    .frame(minWidth: 300)
                    .navigationTitle("Groups")
                    .navigationSubtitle("")
            } detail: {
                MacOSMessageDetailView(selectedGroup: $selectedGroup)
                    .frame(minWidth: 500)
            }
            
        }
        .sheet(isPresented: $appState.showOnboarding) {
            //MacOSWelcomeView()
            MacOSStartView()
                .frame(width: 400, height: 500)
        }
        .onAppear {
            if ownerAccounts.isEmpty {
                appState.showOnboarding = true
            }
//            self.appState.selectedRelay = self.appState.relays.first
//            self.selectedGroup = groups.first
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
