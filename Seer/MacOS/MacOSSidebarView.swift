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
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State var tapped: Int = 0
    
    @Query private var ownerAccounts: [OwnerAccount]
    var currentOwnerAccount: OwnerAccount? {
        return ownerAccounts.first(where: { $0.selected })
    }

    var body: some View {
        
        List(selection: $appState.selectedRelay) {
            Section("Chat Relays") {
                ForEach(relays, id: \.url) { relay in
                    NavigationLink(relay.url, value: relay)
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            if columnVisibility == .all {
                ToolbarItemGroup(placement: .automatic) {
                    Spacer()
                    SettingsLink {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            
                LazyVStack(alignment: .leading) {
                    HStack {
                        
                        if let currentOwnerAccount {

                            AvatarView(avatarUrl: currentOwnerAccount.publicKeyMetadata?.picture ?? "", size: 30)
                            //                            .overlay(alignment: .bottomTrailing) {
                            //                                Image(systemName: "checkmark.circle.fill")
                            //                                    .symbolRenderingMode(.multicolor)
                            //                                    .offset(x: 5, y: 1)
                            //                            }
                            VStack(alignment: .leading) {
                                Text(verbatim: currentOwnerAccount.bestPublicName)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .bold()
                                Text(currentOwnerAccount.publicKeyMetadata?.bech32PublicKey ?? currentOwnerAccount.publicKey)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                            
                            SettingsLink(label: {
                                Image(systemName: "gearshape")
                            })
                            .buttonStyle(.plain)
                            
                        } else {
                            
                            Button(action: { appState.showWelcome = true }) {
                                LazyVStack {
                                    Label("Add Account", systemImage: "person.crop.circle.badge.plus")
                                        .padding(8)
                                }
                            }
                            .buttonStyle(.bordered)
                            
                        }
                        

                    }
                    .padding(8)
                }
                .background(.regularMaterial)
            
        }
        
    }
}

//#Preview {
//    MacOSSidebarView()
//}
