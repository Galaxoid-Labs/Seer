//
//  WelcomeView.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import SwiftUI
import Nostr
import SwiftData

struct WelcomeView: View {
    
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showImport = false
    @State private var textInput = ""
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.clear
                .overlay(alignment: .top) {
                    Image("seer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(alignment: .topLeading) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .safeAreaInset(edge: .bottom) {
            
            VStack(spacing: 8) {
               
                VStack(spacing: 2) {
                    Text("Seer")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(.white)
                        .italic()
                    
                    Text("A nip-29 group chat client for nostr")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .offset(x: 0, y: -8)
                        
                }
                .frame(maxWidth: .infinity)

                VStack {
                    
                    if showImport {
                        
                        SecureField("nsec1...", text: $textInput)
                            .textFieldStyle(.roundedBorder)
                            .cornerRadius(4)
                        
                        HStack(alignment: .center) {
                            
                            Button(action: { self.showImport.toggle() }) {
                                Text("Back")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                if let ownerAccount = OwnerAccount.restore(withPrivateKeyHexOrNsec: textInput) {
                                    if let currentOwners = try? modelContext.fetch(FetchDescriptor<OwnerAccount>()) {
                                        for owner in currentOwners {
                                            owner.selected = false
                                        }
                                    }
                                    ownerAccount.selected = true
                                    modelContext.insert(ownerAccount)
                                    appState.tryBootstrapingOwnerAccountMetadataRelays()
                                    dismiss()
                                } else {
                                    print("damn")
                                }
                            }) {
                                Text("Import")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                    } else {
                        
                        Button(action: { self.showImport.toggle() }) {
                            Text("Import")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            if let ownerAccount = OwnerAccount.createNew() {
                                withAnimation {
                                    modelContext.insert(ownerAccount)
                                    dismiss()
                                }
                            }
                        }) {
                            Text("Create")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                }
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .overlay(alignment: .topTrailing) {
                SettingsLink {
                    Image(systemName: "network")
                }
                .padding(12)
            }
            .background(.black)
            
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .frame(width: 300, height: 500)
    }
}
