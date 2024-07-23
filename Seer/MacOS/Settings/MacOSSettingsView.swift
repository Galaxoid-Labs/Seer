//
//  MacOSSettingsView.swift
//  Seer
//
//  Created by Jacob Davis on 4/16/24.
//
#if os(macOS)
import SwiftUI

struct MacOSSettingsView: View {

    private enum Tabs: Hashable {
        case general
        case accounts
        case relays
    }

    var body: some View {
        TabView {
//            Text("General Settings")
//                .tabItem {
//                    Label("General", systemImage: "gearshape")
//                }
//                .tag(Tabs.general)
            MacOSSettingsAccountView()
                .tabItem {
                    Label("Accounts", systemImage: "person.2")
                }
                .tag(Tabs.accounts)
            MacOSSettingsRelayView()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(Tabs.relays)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
    }
}

#Preview {
    MacOSSettingsView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
#endif
