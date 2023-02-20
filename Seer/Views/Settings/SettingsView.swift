//
//  SettingsView.swift
//  Seer
//
//  Created by Jacob Davis on 2/20/23.
//

import SwiftUI
import RealmSwift

struct SettingsView: View {

    private enum Tabs: Hashable {
        case general
        case accounts
        case relays
    }

    var body: some View {
        TabView {
            Text("General Settings")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tabs.general)
            SettingsAccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "person.2")
                }
                .tag(Tabs.accounts)
            SettingsRelayView()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(Tabs.relays)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
