//
//  MacOSGroupInfoPopoverView.swift
//  Seer
//
//  Created by Jacob Davis on 8/7/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct MacOSGroupInfoPopoverView: View {
    
    let group: GroupVM
    let members: [GroupMemberVM]
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 16) {
                
                AnimatedImage(url: URL(string: group.picture ?? ""), placeholder: {
                    Image(systemName: "rectangle.3.group.bubble")
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                })
                .resizable()
                .frame(width: 50, height: 50)
                .aspectRatio(contentMode: .fill)
                .background(.gray)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack {
                    Text(group.name ?? "")
                        .font(.title2)
                        .bold()
                    
                    Text(group.about ?? "")
                        .font(.subheadline)
                }
                .multilineTextAlignment(.center)
                
                Divider()
                
                Section("Members") {
                    ForEach(members) { member in
                        HStack {
                            AvatarView(avatarUrl: member.metadata?.picture ?? "", size: 30)
                                .overlay(alignment: .bottomTrailing) {
        //                                    Image(systemName: "checkmark.circle.fill")
        //                                        .symbolRenderingMode(.multicolor)
        //                                        .offset(x: 5, y: 1)
                                }
                            VStack(alignment: .leading) {
                                Text(verbatim: member.metadata?.bestPublicName ?? member.publicKey)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .bold()
                                Text(member.metadata?.bech32PublicKey ?? member.publicKey)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                
            }
            .padding()
            
        }
        
    }
}

#Preview {
    MacOSGroupInfoPopoverView(group: .init(id: "abc123", relayUrl: "wss://groups.fiatjaf.com", name: "Horse", picture: "https://fiatjaf.com/static/favicon.jpg", about: "A group non-related to horses", isPublic: true, isOpen: true), members: [
            GroupMemberVM(publicKey: "abc", groupId: "abc123"),
            GroupMemberVM(publicKey: "def", groupId: "abc123"),
        ])
        .frame(width: 300, height: 400)
}
