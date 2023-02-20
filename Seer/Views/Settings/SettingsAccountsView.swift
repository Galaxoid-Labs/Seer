//
//  SettingsAccountsView.swift
//  Seer
//
//  Created by Jacob Davis on 2/20/23.
//

import SwiftUI
import RealmSwift

struct SettingsAccountsView: View {

    private enum Tabs: Hashable {
        case info
        case relays
    }
    
    @ObservedResults(OwnerKey.self) var ownerKeys
    
    @State private var selectedOwnerKey: OwnerKey?
    @State private var tabs = 0

    var body: some View {
        HStack {
            
            GroupBox {
                List(ownerKeys) { ownerKey in
                    SettingsAccountsListRowView(ownerKey: ownerKey, selectedOwnerKey: $selectedOwnerKey)
                }
                .listStyle(.bordered)
                .frame(width: 250)
            }
            .padding(.top, 10)

            TabView {

                Form {
                    
                    Section("") {
                        LazyVStack(alignment: .center) {
                            AvatarView(avatarUrl: selectedOwnerKey?.publicKeyMetaData?.picture ?? "", size: 75)
                        }
                        TextField("Picture", text: .constant(selectedOwnerKey?.publicKeyMetaData?.picture ?? ""))
                    }

                    Section("") {
                        TextField("Name", text: .constant(selectedOwnerKey?.publicKeyMetaData?.name ?? ""))
                        TextField("About", text: .constant(selectedOwnerKey?.publicKeyMetaData?.about ?? ""))
                    }

                    Section("Bech32 Public Key") {
                        Text(selectedOwnerKey?.publicKeyMetaData?.bech32PublicKey ?? "")
                    }
                    Section("Hex Public Key") {
                        Text(selectedOwnerKey?.publicKeyMetaData?.publicKey ?? "")
                    }
                    
                    HStack {
                        Text("Last updated on")
                        Spacer()
                        Text(selectedOwnerKey?.publicKeyMetaData?.createdAt ?? Date.now, style: .date)
                    }
                }
                .textSelection(.enabled)
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .tabItem {
                    Text("Info")
                }

                SettingsAccountsRelayView(ownerKey: $selectedOwnerKey)
                    .tabItem {
                        Text("Relays")
                    }
            }
            .tabViewStyle(.automatic)

        }
        .onAppear {
            self.selectedOwnerKey = self.ownerKeys.first
        }
    }
}

struct SettingsAccountsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAccountsView()
    }
}
