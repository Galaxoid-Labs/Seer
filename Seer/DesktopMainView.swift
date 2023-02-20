//
//  DesktopMainView.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import SwiftUI
import RealmSwift
import KeychainAccess

#if os(macOS)
struct DesktopMainView: View {
    
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var appState: AppState
    
    @ObservedResults(OwnerKey.self) var ownerKeys
    @ObservedResults(PublicKeyMetaData.self) var publicKeyMetaDatas
    @ObservedResults(EncryptedMessage.self) var encryptedMessages
    
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var showWelcome = false
    
    var selectedOwnerKey: OwnerKey? {
        return navigation.sidebarValue.ownerKey
    }
    
    var body: some View {
        ZStack {
            if ownerKeys.count > 0 {

                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView()
                        .toolbar {
                            ToolbarItem {
                                Button {
                                    self.showWelcome = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                } content: {
                    if navigation.sidebarValue.ownerKey != nil {
                        MessagesContentView()
                    }
                } detail: {
                    if navigation.contentValue.publicKeyMetaData != nil {
                        MessagesDetailView()
                    }
                }
                
            } else {
                ZStack {
                    TileBackground()
                    VStack {
                        Button(action: {
                            self.showWelcome.toggle()
                        }) {
                            Text("Get Started")
                                .frame(width: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeView()
                .frame(width: 300, height: 500)
        }
        .onAppear {
            if ownerKeys.count == 0 {
                showWelcome = true
            }
        }
    }
}

struct DesktopMainView_Previews: PreviewProvider {
    static var previews: some View {
        DesktopMainView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
    }
}
#endif
