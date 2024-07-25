//
//  MacOSStartView.swift
//  Seer
//
//  Created by Jacob Davis on 7/23/24.
//

import SwiftUI

import SwiftUI
import Nostr
import SwiftData

struct MacOSStartView: View {
    
    //@EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            
            ZStack(alignment: .center) {
                Color.clear
                    .overlay(alignment: .top) {
                        Image("seer")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
            }
            .edgesIgnoringSafeArea(.all)
            .safeAreaInset(edge: .bottom) {
                
                VStack(spacing: 8) {
                   
                    VStack(spacing: 2) {
                        Text("Seer")
                            .font(.system(size: 56, weight: .black))
                            .foregroundColor(.white)
                            .italic()
                        
                        Text("A nip-29 group chat client for Nostr")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .offset(x: 0, y: -8)
                            
                    }
                    .frame(maxWidth: .infinity)

                    LazyVStack {
                        NavigationLink("Get Started", value: 0)
                            .buttonStyle(.borderedProminent)
                            
                    }
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(.black)
                
            }
            .navigationDestination(for: Int.self) { t in
                switch t {
                    case 0:
                        MacOSStartAddChatRelay(navigationPath: $navigationPath)
                            .navigationBarBackButtonHidden()
                    case 1:
                        MacOSStartAddMetadataRelay(navigationPath: $navigationPath)
                            .navigationBarBackButtonHidden()
                    case 2:
                        MacOSStartAddAccountView(navigationPath: $navigationPath)
                            .navigationBarBackButtonHidden()
                    default:
                        Text("Something went wrong...")
                }
            }
        }

    }
}

#Preview {
    MacOSStartView()
        .frame(width: 400, height: 500)
}
