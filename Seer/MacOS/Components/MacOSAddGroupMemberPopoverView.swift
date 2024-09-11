//
//  MacOSAddGroupMemberPopoverView.swift
//  Seer
//
//  Created by Jacob Davis on 8/8/24.
//

import SwiftUI
import SwiftData
import Nostr

struct MacOSAddGroupMemberPopoverView: View {
    
    @EnvironmentObject var appState: AppState 
    @Environment(\.dismiss) private var dismiss
    
    let members: [GroupMember]
    let selectedGroup: Group
    let selectedOwnerAccount: OwnerAccount
   
//    @Query var publicKeyMetadata: [PublicKeyMetadata]
//    var filteredPublicKeyMetadata: [PublicKeyMetadata] {
//        return publicKeyMetadata.filter { pmd in
//            !members.contains { gm in
//                gm.publicKey == pmd.publicKey
//            }
//        }
//    }
    
    @State private var inputText = ""
    
    var body: some View {
        
        ScrollView {
            
            TextField("npub... or hex", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            ForEach(members, id: \.id) { member in
                HStack {
                    AvatarView(avatarUrl: member.publicKeyMetadata?.picture ?? "", size: 30)
                    
                    VStack(alignment: .leading) {
                        Text(verbatim: member.publicKeyMetadata?.bestPublicName ?? member.publicKey)
                            .lineLimit(1)
                            .font(.subheadline)
                            .bold()
                        Text(member.publicKeyMetadata?.bech32PublicKey ?? member.publicKey)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .textSelection(.enabled)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            appState.addMember(ownerAccount: selectedOwnerAccount,
                                               group: selectedGroup, publicKey: member.publicKey)
                        }
                        dismiss()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(.accent)
                    }
                    .buttonStyle(.plain)
                    
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

//#Preview {
//    MacOSAddGroupMemberPopoverView(members: [
//        GroupMemberVM(publicKey: "abc", groupId: "abc123"),
//        GroupMemberVM(publicKey: "def", groupId: "abc123")],
//                                   selectedGroup: GroupVM(id: "abc", relayUrl: "", isPublic: true, isOpen: true),
//                                   selectedOwnerAccount: OwnerAccount(publicKey: "abc", selected: true, metadataRelayIds: [], messageRelayIds: []))
//        .frame(width: 200, height: 400)
//}
