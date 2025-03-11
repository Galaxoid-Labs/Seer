//
//  MacOSSearchGroupsView.swift
//  Seer
//
//  Created by Jacob Davis on 3/11/25.
//

import SwiftUI
import SwiftData

struct MacOSSearchGroupsView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Query private var groups: [Group]
    
    init(relayUrl: String) {
        _groups = Query(
            filter: Group.predicate(relayUrl: relayUrl, isMember: false),
            sort: [SortDescriptor(\.name, order: .forward)]
        ) // TODO: order by last message?
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.id) { group in
                    NavigationLink(value: group) {
                        MacOSSearchGroupListRowView(group: group)
                    }
                }
            }
            .frame(minHeight: 400)
            .navigationTitle(Text("Search Groups"))
        }
    }
}

#Preview {
    MacOSSearchGroupsView(relayUrl: "wss://groups.fiatjaf.com")
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
