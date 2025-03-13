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
    @Environment(\.dismiss) var dismiss
    
    @Query private var groups: [Group]
    
    init(relayUrl: String) {
        _groups = Query(
            filter: Group.predicate(relayUrl: relayUrl, isMember: false),
            sort: [SortDescriptor(\.name, order: .forward)]
        ) // TODO: order by last message?
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            List(groups, id: \.id) { group in
                MacOSSearchGroupListRowView(group: group)
            }
            .frame(minHeight: 400)
            Divider()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(.thinMaterial)
        }
    }
}

#Preview {
    MacOSSearchGroupsView(relayUrl: "wss://groups.fiatjaf.com")
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
