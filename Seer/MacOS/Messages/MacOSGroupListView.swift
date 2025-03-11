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
    
    @State private var showCreateGroupSheet: Bool = false
    @State private var showSearchGroupSheet: Bool = false

    func latestMessage(for groupId: String) -> ChatMessage? {
        return chatMessages
            .filter({ $0.groupId == groupId })
            .sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    init(relayUrl: String) {
        self.relayUrl = relayUrl
        _groups = Query(
            filter: Group.predicate(relayUrl: relayUrl, isMember: true),
            sort: [SortDescriptor(\.name, order: .forward)]
        ) // TODO: order by last message?
        _chatMessages = Query(filter: ChatMessage.predicate(relayUrl: relayUrl))
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
                
                Menu("", systemImage: "plus.circle") {
                    Button {
                        showCreateGroupSheet = true
                    } label: {
                        Label("Create a Group", systemImage: "person.3.fill")
                    }
                    .labelStyle(.titleAndIcon)
                    
                    Button {
                        showSearchGroupSheet = true
                    } label: {
                        Label("Find a Group", systemImage: "magnifyingglass")
                    }
                    .labelStyle(.titleAndIcon)
                }
                
                //Spacer()
//                Button(action: {
//                    appState.createGroup(ownerAccount: appState.selectedOwnerAccount!)
//                }) {
//                    Image(systemName: "plus.circle")
//                }
                
            }
            
        }
        .sheet(isPresented: $showCreateGroupSheet) {
            
        } content: {
            MacOSCreateGroupView()
        }
        .sheet(isPresented: $showSearchGroupSheet) {
            
        } content: {
            MacOSSearchGroupsView(relayUrl: self.relayUrl)
        }

    }
}

#endif
