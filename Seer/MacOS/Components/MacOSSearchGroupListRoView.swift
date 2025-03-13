//
//  MacOSSearchGroupListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 3/11/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct MacOSSearchGroupListRowView: View {
    
    @EnvironmentObject var appState: AppState
    
    let group: Group
    
    var body: some View {
        
        HStack {
            
            AnimatedImage(url: URL(string: group.picture ?? ""), placeholder: {
                Text(group.name?.prefix(1) ?? "")
                    .fontWeight(.black)
                    .font(.title)
            })
            .resizable()
            .frame(width: 60, height: 60)
            .aspectRatio(contentMode: .fill)
            .background(.gray)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading) {
                Text(group.name ?? "")
                    .font(.headline)
                    .bold()
                
                Text(group.id)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
                
                Text(group.about ?? "")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if group.isOpen && group.isPublic && !group.isMember && !group.isAdmin {
                Button("Join") {
                    guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                    appState.joinGroup(ownerAccount: selectedOwnerAccount, group: group)
                }
                .buttonStyle(.borderedProminent)
            } else if !group.isMember && !group.isAdmin {
                Button("Get Invite") {
                    
                }
                .buttonStyle(.borderedProminent)
            } else if group.isMember || group.isAdmin {
                Button("Leave") {
                    
                }
                .buttonStyle(.bordered)
            }

            
        }
        .frame(height: 60)
    }
}

#Preview {
    MacOSSearchGroupListRowView(
        group: Group(
            id: "016fb665",
            relayUrl: "wss://groups.fiatjaf.com", name: "A cool group",
//            picture: "https://transforms.stlzoo.org/production/animals/amur-tiger-01-01.jpg?w=1200&h=1200&auto=compress%2Cformat&fit=crop&dm=1658935145&s=95d03aceddd44dc8271beed46eae30bc",
            about: "This group is about alot of cool things that should be in a group",
            isPublic: true,
            isOpen: true,
            isMember: false,
            isAdmin: false
        )
    )
    .frame(minWidth: 200)
}
