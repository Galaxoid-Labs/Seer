//
//  DirectMessagesView.swift
//  Seer
//
//  Created by Jacob Davis on 12/16/22.
//

import SwiftUI
//import NostrKit
import RealmSwift
import SDWebImageSwiftUI

struct DirectMessagesView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @EnvironmentObject var navigation: Navigation

    @State private var scrollChange: Int = 0
    @State private var viewIsVisible = true
    
    @ObservedResults(REncryptedDirectMessage.self) var directMessageResults
    var contactedUserProfiles: [RUserProfile] {
        let contactedMessages = directMessageResults.filter({ $0.publicKey == nostrData.selectedOwnerUserProfile?.publicKey })
        let userProfileSet = Set(contactedMessages.compactMap({ $0.otherUserProfile }))
        return Array(userProfileSet).sorted(by: { ($0.getLatestMessage()?.createdAt ?? Date.now) > ($1.getLatestMessage()?.createdAt ?? Date.now) })
    }
    
    var unknownUserProfiles: [RUserProfile] {
        let unknownMessages = directMessageResults.filter({ $0.publicKey != nostrData.selectedOwnerUserProfile?.publicKey && $0.otherUserProfile?.hasContacted() == false })
        let userProfileSet = Set(unknownMessages.compactMap({ $0.otherUserProfile }))
        return Array(userProfileSet).sorted(by: { ($0.getLatestMessage()?.createdAt ?? Date.now) > ($1.getLatestMessage()?.createdAt ?? Date.now) })
    }
    
    let homeTapped = NotificationCenter.default.publisher(for: NSNotification.Name("HomeTapped"))
    
    var body: some View {
        ScrollViewReader { reader in
            List {
                if contactedUserProfiles.count > 0 || unknownUserProfiles.count > 0 {
                    if contactedUserProfiles.count > 0 {
                        Section("Known Users") {
                            ForEach(contactedUserProfiles) { userProfile in
                                DirectMessageListViewRow(userProfile: userProfile)
                                    .id(userProfile.publicKey)
                            }
                        }
                    }
                    if unknownUserProfiles.count > 0 {
                        Section("Unknown Users") {
                            ForEach(unknownUserProfiles) { userProfile in
                                DirectMessageListViewRow(userProfile: userProfile)
                                    .id(userProfile.publicKey)
                            }
                        }
                    }
                } else {
                    
                    VStack(alignment: .center, spacing: 16) {
                        Text("No Encrypted Messages Found")
                        Image(systemName: "tray.fill")
                    }
                    .frame(maxWidth: .infinity)
                    
                }
            }
            .listStyle(.insetGrouped)
            .navigationDestination(for: Navigation.NavUserProfile.self) { nav in
                ProfileDetailView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavFollowing.self) { nav in
                FollowingView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavFollowers.self) { nav in
                FollowersView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavDirectMessage.self) { nav in
                DirectMessageView(userProfile: nav.userProfile)
            }
            .onReceive(homeTapped) { (output) in
                if !navigation.homePath.isEmpty {
                    navigation.homePath.removeLast()
                } else {
                    //NostrData.shared.updateLastSeenDate()
                }
                scrollChange += 1
            }
            .onChange(of: scrollChange) { value in
                if viewIsVisible {
                    withAnimation {
                        reader.scrollTo(contactedUserProfiles.first?.id, anchor: .top)
                    }
                }
            }
            .onDisappear {
                viewIsVisible = false
            }
            .onAppear {
                viewIsVisible = true
            }
        }
    }
}

struct DirectMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        DirectMessagesView()
            .environmentObject(NostrData.shared)
            .environmentObject(Navigation())
    }
}

struct DirectMessageListViewRow: View {
    
    @ObservedRealmObject var userProfile: RUserProfile
    @EnvironmentObject var navigation: Navigation
    
    var body: some View {
        HStack (alignment: .top, spacing: 12) {
            AnimatedImage(url: userProfile.avatarUrl)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(
                    Image(systemName: "person.crop.circle.fill").foregroundColor(.secondary).font(.system(size: 48))
                )
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .onTapGesture {
                    self.navigation.homePath.append(Navigation.NavUserProfile(userProfile: userProfile))
                }
            
            VStack (alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let name = userProfile.name, name.isValidName()  {
                        Text("@"+name)
                            .font(.system(.subheadline, weight: .bold))
                    }
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "key.fill")
                            .imageScale(.small)
                        Text(userProfile.bech32PublicKey.prefix(12))
                    }
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    Text((userProfile.getLatestMessage()?.createdAt ?? .now), style: .offset)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Text(userProfile.getLatestMessage()?.decryptedContent ?? "Not sure?")
                    .font(.callout)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
            }
            .contentShape(Rectangle())
            .onTapGesture {
                self.navigation.homePath.append(Navigation.NavDirectMessage(userProfile: userProfile))
            }
            .onAppear {
                
                
                if userProfile.bech32PublicKey == "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m" {
                    print(userProfile)
                }
            }
            
        }
        
    }
}
