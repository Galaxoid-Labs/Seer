//
//  MacOSSidebarView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

import SwiftUI
import SwiftData

struct MacOSSidebarView: View {
    
    @EnvironmentObject var appState: AppState
    @Query private var relays: [Relay]

    var body: some View {
        
        List(selection: $appState.selectedRelay) {
            Section("Chat Relays") {
                ForEach(relays, id: \.url) { relay in
                    NavigationLink(relay.url, value: relay)
                }
            }
        }
        .navigationTitle("Split View")
        .listStyle(.sidebar)
        
    }
}

//#Preview {
//    MacOSSidebarView()
//}
