//
//  MacOSSidebarRelayListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 7/2/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct MacOSSidebarRelayListRowView: View {
    
    @EnvironmentObject var appState: AppState
    
    let iconUrl: String
    let relayUrl: String
    let connected: Bool
    
    var connectionColor: Color {
        if appState.selectedRelay?.url == relayUrl {
            if connected {
                return .primary
            }
        } else {
            if connected {
                return .primary
            }
        }
        return .red
    }
    
    var body: some View {
        HStack {
            AnimatedImage(url: URL(string: iconUrl), placeholder: {
                Image(systemName: "network")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            })
            .resizable()
            .frame(width: 30, height: 30)
            .aspectRatio(contentMode: .fill)
            .background(.gray)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(relayUrl)
            Spacer()

            Image(systemName: connected ? "wifi" : "wifi.exclamationmark")
//                .fontWeight(.bold)
                .font(.system(size: 12))
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
                //.scaleEffect(1.4)
                .foregroundStyle(connectionColor)
        }
        .contextMenu {
            if !connected {
                Button("Connect") {
                    appState.nostrClient.connect(relayWithUrl: relayUrl)
                }
            } else {
                Button("Disconnect") {
                    appState.nostrClient.disconnect(relayWithUrl: relayUrl)
                }
            }
        }
    }
}

#Preview {
    MacOSSidebarRelayListRowView(iconUrl: "", relayUrl: "wss://relay29.galaxoidlabs.com", connected: false)
        .environmentObject(AppState.shared)
}
