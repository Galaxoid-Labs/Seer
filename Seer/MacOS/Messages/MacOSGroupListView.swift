//
//  MacOSGroupListView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSGroupListView: View {
    
    @EnvironmentObject var appState: AppState

    let relayUrl: String
    
    @Query private var groups: [Group]
    @Query private var chatMessages: [ChatMessage]
    
    func latestMessage(for groupId: String) -> ChatMessage? {
        return chatMessages
            .filter({ $0.groupId == groupId })
            .sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    init(relayUrl: String) {
        self.relayUrl = relayUrl
        _groups = Query(filter: #Predicate<Group> { $0.relayUrl == relayUrl })
        _chatMessages = Query(filter: #Predicate<ChatMessage> { $0.relayUrl == relayUrl })
    }
    
    var body: some View {
        
        List(selection: $appState.selectedGroup) {
            ForEach(groups, id: \.id) { group in
                NavigationLink(value: group) {
                    MacOSGroupListRowView(group: group, lastMessage: latestMessage(for: group.id))
                }
            }
        }
        .listStyle(.automatic)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                Button(action: {
                    appState.createGroup(ownerAccount: appState.selectedOwnerAccount!)
                }) {
                    Image(systemName: "plus.circle")
                }
                
            }
            
        }
    }
}

#endif
