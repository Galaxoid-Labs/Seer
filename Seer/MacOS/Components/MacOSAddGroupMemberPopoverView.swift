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
    
    let members: [GroupMemberVM]
    let selectedGroup: GroupVM
    let selectedOwnerAccount: OwnerAccount
    
    @Query(filter: #Predicate<DBEvent> { $0.kind == kindSetMetdata }, sort: \.createdAt)
    private var publicKeyMetadataEvents: [DBEvent]
    var publicKeyMetadata: [PublicKeyMetadataVM] {
        let pmd = publicKeyMetadataEvents.compactMap({ PublicKeyMetadataVM(event: $0) })
        return pmd.filter { pmd in
            !members.contains { gm in
                gm.publicKey == pmd.publicKey
            }
        }
    }
    
    @State private var inputText = ""
    
    var body: some View {
        
        ScrollView {
            
            TextField("npub... or hex", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            ForEach(publicKeyMetadata) { pmd in
                HStack {
                    AvatarView(avatarUrl: pmd.picture ?? "", size: 30)
                    
                    VStack(alignment: .leading) {
                        Text(verbatim: pmd.bestPublicName)
                            .lineLimit(1)
                            .font(.subheadline)
                            .bold()
                        Text(pmd.bech32PublicKey)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .textSelection(.enabled)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            appState.addMember(ownerAccount: selectedOwnerAccount,
                                               group: selectedGroup, publicKey: pmd.publicKey)
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

#Preview {
    MacOSAddGroupMemberPopoverView(members: [
        GroupMemberVM(publicKey: "abc", groupId: "abc123"),
        GroupMemberVM(publicKey: "def", groupId: "abc123")],
                                   selectedGroup: GroupVM(id: "abc", relayUrl: "", isPublic: true, isOpen: true),
                                   selectedOwnerAccount: OwnerAccount(publicKey: "abc", selected: true, metadataRelayIds: [], messageRelayIds: []))
        .frame(width: 200, height: 400)
}
