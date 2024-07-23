//
//  MacOSSidebarRelayListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 7/2/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct MacOSSidebarRelayListRowView: View {
    
    let iconUrl: String
    let relayUrl: String
    
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
        }
    }
}

#Preview {
    MacOSSidebarRelayListRowView(iconUrl: "", relayUrl: "wss://relay29.galaxoidlabs.com")
}
