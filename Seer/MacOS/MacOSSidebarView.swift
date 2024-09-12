//
//  MacOSSidebarView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

#if os(macOS)
import SwiftUI
import SwiftData
import SDWebImageSwiftUI

struct MacOSSidebarView: View {
    
    @EnvironmentObject var appState: AppState
   
    @Query private var relays: [Relay]
    var chatRelays: [Relay] {
        return relays.filter({ $0.supportsNip29 })
    }
    
    @Query private var publicKeyMetadata: [PublicKeyMetadata]
    var selectedOwnerAccountPublicKeyMetadata: PublicKeyMetadata? {
        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return nil }
        return publicKeyMetadata.first(where: { $0.publicKey == selectedOwnerAccount.publicKey })
    }
    
    func connectionStatus(for relayUrl: String) -> Bool {
        return appState.statuses.first(where: { $0.key == relayUrl })?.value ?? false
    }
    
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State var tapped: Int = 0
    
    var body: some View {
        
        List(selection: $appState.selectedRelay) {
            Section("Chat Relays") {
                ForEach(chatRelays, id: \.url) { relay in
                    NavigationLink(value: relay) {
                        MacOSSidebarRelayListRowView(iconUrl: relay.icon, relayUrl: relay.url, connected: connectionStatus(for: relay.url))
                    }
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
                        
                        if let selectedOwnerAccount = appState.selectedOwnerAccount {

                            AvatarView(avatarUrl: selectedOwnerAccountPublicKeyMetadata?.picture ?? "", size: 30)
                            
                            VStack(alignment: .leading) {
                                Text(verbatim: selectedOwnerAccountPublicKeyMetadata?.bestPublicName ?? selectedOwnerAccount.bestPublicName)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .bold()
                                Text(selectedOwnerAccountPublicKeyMetadata?.bech32PublicKey ?? selectedOwnerAccount.publicKey)
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
                            
                            Button(action: { appState.showOnboarding = true }) {
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

#endif
