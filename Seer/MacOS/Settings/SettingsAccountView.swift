//
//  SettingsAccountView.swift
//  Seer
//
//  Created by Jacob Davis on 4/18/24.
//

import SwiftUI
import SwiftData

struct SettingsAccountView: View {
    
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var ownerAccounts: [OwnerAccount]
    @State private var selectedOwnerAccount: OwnerAccount?
    
    var body: some View {
        HStack {
            
            GroupBox {
                List(ownerAccounts, selection: $selectedOwnerAccount) { ownerAccount in
                    SettingsAccountListRowView(ownerKey: ownerAccount, selectedOwnerAccount: $selectedOwnerAccount)
                }
                .listStyle(.bordered)
                .frame(width: 250)
            }
            
            if let selectedOwnerAccount {
                
                TabView {

                    Form {
                        
                        Section("") {
                            if let picture = selectedOwnerAccount.publicKeyMetadata?.picture, !picture.isEmpty {
                                LazyVStack(alignment: .center) {
                                    AvatarView(avatarUrl: picture, size: 75)
                                }
                            } else {
                                LazyVStack(alignment: .center) {
                                    AvatarView(avatarUrl: "", size: 75)
                                }
                            }

                            TextField("Picture", text: .constant(selectedOwnerAccount.publicKeyMetadata?.picture ?? ""), prompt: Text("Enter image url"))
                        }

                        Section("") {
                            TextField("Name", text: .constant(selectedOwnerAccount.publicKeyMetadata?.name ?? ""), prompt: Text("Enter name here"))
                            TextField("About", text: .constant(selectedOwnerAccount.publicKeyMetadata?.about ?? ""), prompt: Text("Enter about text here"))
                        }

                        Section("Bech32 Public Key") {
                            Text(selectedOwnerAccount.publicKeyMetadata?.bech32PublicKey ?? "")
                        }
                        Section("Hex Public Key") {
                            Text(selectedOwnerAccount.publicKey ?? "")
                        }
                        
                        HStack {
                            Text("Last updated on")
                            Spacer()
                            Text(selectedOwnerAccount.publicKeyMetadata?.createdAt ?? Date.now, style: .date)
                        }
                        
                        Section("Danger Zone") {
                            Button(action: {
                                self.modelContext.delete(selectedOwnerAccount)
                            }, label: {
                                Text("Remove Account")
                            })
                        }
                        .foregroundStyle(.red)
                        

                    }
                    .textSelection(.enabled)
                    .formStyle(.grouped)
                    .scrollContentBackground(.hidden)
                    .tabItem {
                        Text("Info")
                    }

    //                SettingsAccountsRelayView(ownerKey: $selectedOwnerKey)
    //                    .tabItem {
    //                        Text("Relays")
    //                    }
                }
                .tabViewStyle(.automatic)
                
            } else {
                
                LazyVStack {
                    Button(action: {
                        self.dismiss()
                        appState.showWelcome = true
                    }, label: {
                        Text("Add Account")
                    })
                }
                
            }
            

        }
        .onAppear {
            self.selectedOwnerAccount = ownerAccounts.first
            print(self.selectedOwnerAccount)
        }

    }
}

#Preview {
    SettingsAccountView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
