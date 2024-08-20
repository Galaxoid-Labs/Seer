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
    let admins: [GroupAdminVM]
    let selectedOwnerAccount: OwnerAccount
    
    var filteredMembers: [GroupMemberVM] {
        return members.filter({ gm in !admins.contains { gma in
            gma.publicKey == gm.publicKey
        }})
    }
    
    var selectedOwnerAccountAdmin: GroupAdminVM? {
        return admins.first(where: { $0.publicKey == selectedOwnerAccount.publicKey })
    }
    
    var canRemoveUsers: Bool {
        guard let selectedOwnerAccountAdmin else { return false}
        return Set([GroupAdminVM.Capability.RemoveUser])
        .isSubset(of: selectedOwnerAccountAdmin.capabilities)
    }
    
    @State private var addMemberPopoverShowing = false
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 16) {
                
                HStack {
                    Link("\(group.relayUrl)'\(group.id)", destination: URL(string: "\(group.relayUrl)'\(group.id)")!)
                        .underline()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
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
                    if let name = group.name {
                        Text(name)
                            .font(.title2)
                            .bold()
                    }
                    if let about = group.about {
                        Text(about)
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text(group.isPublic ? "Public" : "Private")
                            .padding(5)
                            .background(group.isPublic ? .accent : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(group.isOpen ? "Open" : "Closed")
                            .padding(5)
                            .background(group.isOpen ? .accent : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
                
                if let selectedOwnerAccountAdmin {
                    Button("Edit Group", systemImage: "rectangle.3.group.bubble") {
                        
                    }
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        
                        if let selectedOwnerAccountAdmin, Set([GroupAdminVM.Capability.AddPermission, GroupAdminVM.Capability.AddUser]).isSubset(of: selectedOwnerAccountAdmin.capabilities) {
                            
                            Button(action: {}, label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.accent)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                    .background(.tertiary.opacity(0.5))
                                    .clipShape(Circle())
                                Text("Add Admin")
                                    .foregroundStyle(.accent)
                                Spacer()
                            })
                            .buttonStyle(.plain)
                            
                        }
                        
                        if canRemoveUsers {
                            
                            ForEach(admins) { member in
                                MacOSGroupInfoMemberListRowView(iconUrl: member.metadata?.picture ?? "",
                                                       name: member.metadata?.bestPublicName ?? member.publicKey,
                                                       publicKey: member.metadata?.bech32PublicKey ?? member.publicKey,
                                                       canRemove: true, action: {})
                            }
                            
                        } else {
                            
                            ForEach(admins) { member in
                                MacOSGroupInfoMemberListRowView(iconUrl: member.metadata?.picture ?? "",
                                                       name: member.metadata?.bestPublicName ?? member.publicKey,
                                                       publicKey: member.metadata?.bech32PublicKey ?? member.publicKey,
                                                       canRemove: false, action: {})
                            }
                            
                        }

                    } header: {
                        Text("Admins")
                            .font(.caption)
                            .bold()
                    }
                    
                    Section {
                        
                        if let selectedOwnerAccountAdmin,
                            selectedOwnerAccountAdmin.capabilities.contains(.AddUser) {
                            
                            Button(action: { addMemberPopoverShowing = true }, label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.accent)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                    .background(.tertiary.opacity(0.5))
                                    .clipShape(Circle())
                                Text("Add Member")
                                    .foregroundStyle(.accent)
                                Spacer()
                            })
                            .buttonStyle(.plain)
                            .popover(isPresented: $addMemberPopoverShowing, content: {
                                MacOSAddGroupMemberPopoverView(members: members, selectedGroup: group, selectedOwnerAccount: selectedOwnerAccount)
                                    .frame(width: 300, height: 300)
                            })
                            
                        }
                        
                        if canRemoveUsers {
                            
                            ForEach(filteredMembers) { member in
                                MacOSGroupInfoMemberListRowView(iconUrl: member.metadata?.picture ?? "",
                                                       name: member.metadata?.bestPublicName ?? member.publicKey,
                                                       publicKey: member.metadata?.bech32PublicKey ?? member.publicKey,
                                                       canRemove: true, action: {})
                            }
                            
                        } else {
                            
                            ForEach(filteredMembers) { member in
                                MacOSGroupInfoMemberListRowView(iconUrl: member.metadata?.picture ?? "",
                                                       name: member.metadata?.bestPublicName ?? member.publicKey,
                                                       publicKey: member.metadata?.bech32PublicKey ?? member.publicKey,
                                                       canRemove: false, action: {})
                            }
                            
                        }
                        
                    } header: {
                        Text("Members")
                            .font(.caption)
                            .bold()
                    }

                }
 
            }
            .padding()
            
        }
        
    }
}

struct MacOSGroupInfoMemberListRowView: View {
    
    let iconUrl: String
    let name: String
    let publicKey: String
    let canRemove: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            AvatarView(avatarUrl: iconUrl, size: 30)
            VStack(alignment: .leading) {
                Text(verbatim: name)
                    .lineLimit(1)
                    .font(.subheadline)
                    .bold()
                Text(publicKey)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            if canRemove {
                Spacer()
                
                Button(action: {
                    Task {
                        action()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    MacOSGroupInfoPopoverView(group: .init(id: "abc123", relayUrl: "wss://groups.fiatjaf.com", name: "Horse", picture: "https://fiatjaf.com/static/favicon.jpg", about: "A group non-related to horses", isPublic: true, isOpen: true), members: [
            GroupMemberVM(publicKey: "abc", groupId: "abc123"),
            GroupMemberVM(publicKey: "def", groupId: "abc123"),
    ], admins: [GroupAdminVM(publicKey: "abc", groupId: "abc123", 
                             capabilities: Set(GroupAdminVM.Capability.allCases))], selectedOwnerAccount: OwnerAccount.init(publicKey: "abc", selected: true, metadataRelayIds: [], messageRelayIds: []))
        .frame(width: 300, height: 400)
}
