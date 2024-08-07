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
    var selectedOwnerAccount: OwnerAccount? {
        return ownerAccounts.first(where: { $0.selected })
    }
    
    var selectedOwnerAccountPublicKeyMetadata: PublicKeyMetadataVM? {
        return publicKeyMetadata.first(where: { $0.publicKey == selectedOwnerAccount?.publicKey })
    }
    
    @Query private var relays: [Relay]
    var chatRelays: [Relay] {
        return relays.filter({ $0.supportsNip29 })
    }
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindGroupMetadata }, sort: \.createdAt)
    private var groupMetadataEvents: [DBEvent]
    var groups: [GroupVM] {
        guard let selectedRelay = appState.selectedRelay else { return [] }
        return groupMetadataEvents.filter({ $0.relayUrl == selectedRelay.url }).compactMap({ GroupVM(event: $0) })
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
        guard let selectedGroup else { return [] }
        guard let selectedRelay = appState.selectedRelay else { return [] }
        let search = "d\(DBEvent.infoDelimiter)\(selectedGroup.id)"
        let memberEvents = groupMemberEvents
            .filter({ $0.relayUrl == selectedRelay.url && $0.serializedTags.contains(search) })
        
        let members = memberEvents.map({ $0.tags.filter({ $0.id == "p" })
            .compactMap({ $0.otherInformation.last }) })
            .reduce([], +)
            .map({ GroupMemberVM(publicKey: $0, groupId: selectedGroup.id, metadata: getPublicKeyMetadata(forPublicKey: $0)) })
        
        return members
    }
   
    func getPublicKeyMetadata(forPublicKey publicKey: String) -> PublicKeyMetadataVM? {
        return publicKeyMetadata.first(where: { $0.publicKey == publicKey })
    }
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindGroupAdmins }, sort: \.createdAt)
    private var groupAdminEvents: [DBEvent]
    var groupAdmins: [GroupAdminVM] {
        guard let selectedGroup else { return [] }
        guard let selectedRelay = appState.selectedRelay else { return [] }
        let search = "d\(DBEvent.infoDelimiter)\(selectedGroup.id)"
        let memberAdmins = groupAdminEvents
            .filter({ $0.relayUrl == selectedRelay.url && $0.serializedTags.contains(search) })
        
        guard let admins = memberAdmins.map({ $0.tags.filter({ $0.id == "p" })
            .compactMap({ $0.otherInformation }) })
            .first?.compactMap({
                GroupAdminVM(publicKey: $0.first, groupId: selectedGroup.id, capabilities: Array($0[2...]))
            }) else { return [] }
        
        return admins
    }
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindSetMetdata }, sort: \.createdAt)
    private var publicKeyMetadataEvents: [DBEvent]
    var publicKeyMetadata: [PublicKeyMetadataVM] {
        return publicKeyMetadataEvents.compactMap({ PublicKeyMetadataVM(event: $0) })
    }

    var body: some View {
        ZStack {
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                MacOSSidebarView(chatRelays: chatRelays, selectedOwnerAccount: selectedOwnerAccount,
                                 selectedOwnerAccountPublicKeyMetadata: selectedOwnerAccountPublicKeyMetadata,
                                 columnVisibility: $columnVisibility)
                    .frame(minWidth: 275)
            } content: {
                MacOSGroupListView(selectedGroup: $selectedGroup, groups: groups, chatMessages: chatMessages,
                                   lastMessages: lastMessages, groupMembers: groupMembers, groupAdmins: groupAdmins)
                    .frame(minWidth: 300)
                    .navigationTitle("Groups")
                    .navigationSubtitle("")
            } detail: {
                MacOSMessageDetailView(selectedGroup: $selectedGroup, messages: chatMessages, groupMembers: groupMembers,
                                       publicKeyMetadata: publicKeyMetadata)
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
