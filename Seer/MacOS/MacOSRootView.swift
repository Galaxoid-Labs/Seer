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
    @Environment(\.modelContext) private var modelContext
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @State private var selectedGroup: GroupVM?
    @Query private var ownerAccounts: [OwnerAccount]
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindGroupMetadata }, sort: \.createdAt)
    private var groupMetadataEvents: [DBEvent]
    var groups: [GroupVM] {
        return groupMetadataEvents.compactMap({ GroupVM(event: $0) })
    }
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindGroupChatMessage || $0.kind == kindGroupChatMessageReply })
    private var chatMessageEvents: [DBEvent]
    var chatMessages: [ChatMessageVM] {
        if selectedGroup == nil { return [] }
        let search = "h\(DBEvent.infoDelimiter)\(selectedGroup?.id ?? "")"
        return chatMessageEvents
            .filter({ $0.relayUrl == appState.selectedRelay?.url && $0.serializedTags.contains(search) })
            .compactMap({ ChatMessageVM(event: $0) })
            .sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    var lastMessages: [ChatMessageVM] {
        return chatMessageEvents
            .filter({ $0.relayUrl == appState.selectedRelay?.url })
            .compactMap({ ChatMessageVM(event: $0) })
    }
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindGroupMembers }, sort: \.createdAt)
    private var groupMemberEvents: [DBEvent]
    var groupMembers: [GroupMemberVM] {
        if selectedGroup == nil { return [] }
        let search = "d\(DBEvent.infoDelimiter)\(selectedGroup?.id ?? "")"
        let memberEvents = groupMemberEvents
            .filter({ $0.relayUrl == appState.selectedRelay?.url && $0.serializedTags.contains(search) })
        
        let members = memberEvents.map({ $0.tags.filter({ $0.id == "p" })
            .compactMap({ $0.otherInformation.last }) })
            .reduce([], +)
            .map({ GroupMemberVM(publicKey: $0, groupId: selectedGroup?.id ?? "") })
        
        return Array(Set(members))
    }

    var body: some View {
        ZStack {
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                MacOSSidebarView(columnVisibility: $columnVisibility)
                    .frame(minWidth: 275)
            } content: {
                MacOSGroupListView(selectedGroup: $selectedGroup, groups: groups, chatMessages: chatMessages, lastMessages: lastMessages, groupMembers: groupMembers)
                    .frame(minWidth: 300)
                    .navigationTitle("Groups")
                    .navigationSubtitle("")
            } detail: {
                MacOSMessageDetailView(selectedGroup: $selectedGroup, messages: chatMessages, groupMembers: groupMembers)
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
