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
  
    @Binding var selectedGroup: GroupVM?
    let groups: [GroupVM]
    let chatMessages: [ChatMessageVM]
    let lastMessages: [ChatMessageVM]
    
    func latestMessage(for groupId: String) -> ChatMessageVM? {
        return lastMessages
                    .filter({ $0.groupId == groupId }).sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    var body: some View {
       
        List(selection: $selectedGroup) {
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
                Button(action: { print("Add tapped") }) {
                    Image(systemName: "plus.circle")
                }
                
                if let selectedGroup {
                    ShareLink(item: selectedGroup.relayUrl + "'" + selectedGroup.id)
                }
                
            }
            
        }
    }
}

#endif
