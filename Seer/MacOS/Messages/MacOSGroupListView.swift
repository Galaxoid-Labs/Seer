//
//  MacOSGroupListView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

import SwiftUI
import SwiftData

struct MacOSGroupListView: View {
    
    @EnvironmentObject var appState: AppState
  
    @Binding var selectedGroup: SimpleGroup?
    let groups: [SimpleGroup]
    let eventMessages: [EventMessage]
    
    func latestMessage(for groupId: String) -> EventMessage? {
        return eventMessages
                    .filter({ $0.groupId == groupId }).sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    var body: some View {
        
        List(selection: $selectedGroup) {
            ForEach(groups, id: \.id) { group in
                NavigationLink(value: group) {
                    MacOSGroupListRowView(group: group, lastMessage: latestMessage(for: group.id)?.content, lastMessageDate: latestMessage(for: group.id)?.createdAt)
                }
            }
        }
        .listStyle(.automatic)
        
    }
}

//#Preview {
//    MacOSGroupListView()
//}