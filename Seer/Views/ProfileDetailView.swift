//
//  ProfileDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct ProfileDetailView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @EnvironmentObject var navigation: Navigation
    
    @ObservedRealmObject var userProfile: RUserProfile
    
    @ObservedResults(RContactList.self) var contactLists

    @State private var showTitle: Bool = false
    
    var contactList: RContactList? {
        return contactLists.filter("publicKey = %@", userProfile.publicKey).first
    }
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        
        ScrollViewReader { reader in
            
            List {
                
                VStack {
                    
                    HStack(alignment: .center) {
                        AnimatedImage(url: userProfile.avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .background(
                                Image(systemName: "person.crop.circle.fill").foregroundColor(.secondary).font(.system(size: 60))
                            )
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                        
                        Spacer()
                        
                        if !userProfile.lud06.isEmpty {
                            
                            if SeerApp.getAvailableWallets().count > 0 {
                                Menu {
                                    
                                    ForEach(SeerApp.getAvailableWallets()) { wallet in
                                        Button(action: {
                                            if let url = SeerApp.get(lnurl: userProfile.lud06, withScheme: wallet.scheme.rawValue) {
                                                openURL(url)
                                            }
                                        }) {
                                            Text(wallet.name)
                                        }
                                    }
    //                                Button(action: {
    //
    //                                }) {
    //                                    Label("Add", systemImage: "plus.circle")
    //                                }
    //                                Button(action: {
    //
    //                                }) {
    //                                    Label("Delete", systemImage: "minus.circle")
    //                                }
    //                                Button(action: {
    //
    //                                }) {
    //                                    Label("Edit", systemImage: "pencil.circle")
    //                                }
                                } label: {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.orange)
                                        .frame(height: 20)
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button(action: {}) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.orange)
                                        .frame(height: 20)
                                }
                                .buttonStyle(.bordered)
                            }

                        }
                        
                        if userProfile.publicKey != nostrData.selectedOwnerUserProfile?.publicKey {
                            
                            Button(action: {}) {
                                Image(systemName: "text.bubble.fill")
                                    .frame(height: 20)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if userProfile.publicKey != nostrData.selectedOwnerUserProfile?.publicKey {
                            
                            Button(action: {}) {
                                Text("Follow")
                                    .font(.callout)
                                    .frame(height: 20)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                    }
                    
                    HStack {
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            if !userProfile.displayName.isEmpty {
                                Text(userProfile.displayName)
                                    .font(.system(.title3, weight: .bold))
                            }
                            
                            if let name = userProfile.name, name.isValidName() {
                                Text("@"+name)
                                    .font(.subheadline)
                            }
                            
                            Button(action: {}) {
                                HStack(alignment: .center) {
                                    Image(systemName: "key.fill")
                                        .font(.caption2)
                                    Text(userProfile.bech32PublicKey)
                                        .frame(width: 150)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .font(.caption)
//                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                            .buttonStyle(.plain)
                            .buttonBorderShape(.capsule)
                            .foregroundColor(.accentColor)

                        }
                        
                        Spacer()
                        
                    }
                    
                    Divider()
                        .padding(.bottom, 4)
                    
                    if let contactList {
                        HStack(spacing: 12) {
                            Button(action: {
                                if contactList.following.count > 0 {
                                    self.navigation.homePath.append(Navigation.NavFollowing(userProfile: userProfile))
                                }
                            }) {
                                Text("Following")
                                    .foregroundColor(.secondary)
                                +
                                Text(" \(contactList.following.count)")

                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                if contactList.followedBy.count > 0 {
                                    self.navigation.homePath.append(Navigation.NavFollowers(userProfile: userProfile))
                                }
                            }) {
                                Text("Followers")
                                    .foregroundColor(.secondary)
                                +
                                Text(" \(contactList.followedBy.count)")
                                Spacer()
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption)
                        .fontWeight(.medium)

                    } else {
                        HStack {
                            Text("Calculating followers and following...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }

                    }

                }
                .listRowSeparator(.hidden)
                .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                    value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                .onPreferenceChange(ViewOffsetKey.self) {
                    if $0 > -50 {
                        showTitle = true
                    } else {
                        showTitle = false
                    }
                }

            }
            .padding(.top, -24) // Handle weird padding when insetgrouped?
            .listStyle(.insetGrouped)
#if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("")
#endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AnimatedImage(url: userProfile.avatarUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(
                            Image(systemName: "person.crop.circle.fill").foregroundColor(.secondary).font(.system(size: 30))
                        )
                        .frame(width: 30, height: 30)
                        .cornerRadius(15)
                        .opacity(showTitle ? 1.0 : 0.0)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
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
                    }
                    .onTapGesture {
                        UIPasteboard.general.string = userProfile.bech32PublicKey
                    }
                    .opacity(showTitle ? 1.0 : 0.0)
                }
            }
            .coordinateSpace(name: "scroll")
            
        }
        .task {
            nostrData.fetchContactList(forPublicKey: userProfile.publicKey)
        }
        
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileDetailView(userProfile: RUserProfile.preview)
                .environmentObject(NostrData.shared)
                .environmentObject(Navigation())
        }
    }
}
