//
//  DirectMessageView.swift
//  Seer
//
//  Created by Jacob Davis on 12/20/22.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI
import AZVideoPlayer
import AVFoundation

struct DirectMessageView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @EnvironmentObject var navigation: Navigation
    
    @ObservedObject var keyboardManager = KeyboardManager()
    
    @ObservedRealmObject var userProfile: RUserProfile
    @ObservedResults(REncryptedDirectMessage.self,
                     sortDescriptor: SortDescriptor(keyPath: "createdAt",
                                                    ascending: false)) var directMessageResults
    
    var directMessages: [REncryptedDirectMessage] {
        return Array(directMessageResults.filter({ $0.otherUserProfile?.publicKey == userProfile.publicKey }))
    }
    
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 110
    @FocusState private var inputFocused: Bool
    
    private let maxHeight : CGFloat = 350
    
    var body: some View {
        
        ZStack {
            Image("tile_pattern_1")
                .resizable(resizingMode: .tile)
                .colorMultiply(.accentColor)
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [.clear, .clear, Color(.systemBackground).opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                        .blendMode(.luminosity)
                )
            
            ScrollViewReader { reader in
                List {
                    ForEach(directMessages) { dm in
                        DirectMessageCellView(directMessage: dm,
                                              owner: dm.publicKey == nostrData.selectedOwnerUserProfile?.publicKey)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .rotationEffect(Angle(radians: .pi))
                    .scaleEffect(x: -1, y: 1, anchor: .center)

                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)

            }
            .rotationEffect(Angle(radians: .pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
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
            }
        }
        .onAppear {
            
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Text(messageText)
                        .font(.system(.body))
                        .foregroundColor(.clear)
                        .padding(12)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewHeightKey.self,
                                                   value: $0.frame(in: .local).size.height)
                        })
                    
                    TextEditor(text: $messageText)
                        .focused($inputFocused)
                        .font(.system(.body))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                        .frame(height: min(textEditorHeight, maxHeight))
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(style: .init(lineWidth: 0.5))
                                    .fill(Color(.systemGray4))
                            }
                        }
                        .contentShape(Rectangle())
                }

                if !messageText.isEmpty {
                    Button(action: {
                        if !messageText.isEmpty {
                            if nostrData.createEncyrpedDirectMessageEvent(withContent: messageText, forPublicKey: userProfile.publicKey) {
                                withAnimation {
                                    messageText = ""
                                    inputFocused = false
                                }
                            }
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(messageText.isEmpty)
                }
            }
            .padding(12)
            .background(
                .ultraThinMaterial,
                ignoresSafeAreaEdges: .bottom
            )
            .overlay(alignment: .top) {
                Divider()
            }
            .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
        }

    }
    
    func scrollToBottom(reader: ScrollViewProxy) -> Void {
        if let last = directMessageResults.last {
            reader.scrollTo(last.id, anchor: .top)
        }
    }
    
    struct ViewHeightKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = value + nextValue()
        }
    }
}

struct DirectMessageCellView: View {
    
    @ObservedRealmObject var directMessage: REncryptedDirectMessage
    let owner: Bool
    
    var body: some View {
        HStack {
            
            if owner {
                Spacer(minLength: 16)
            }
            
            VStack(alignment: owner ? .trailing : .leading, spacing: 8) {
                Text(directMessage.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack {
                    
                    if let videoUrl = directMessage.videoUrl {
                        
                        VStack(spacing: 0) {
                            AZVideoPlayer(player: AVPlayer(url: videoUrl))
                                .frame(height: 200)
                                .shadow(radius: 0)
                            HStack {
                                Image(systemName: "rectangle.and.hand.point.up.left.fill")
                                    .font(.body)
                                    .fontWeight(.regular)
                                Text("Tap Image to watch video")
                                //Spacer()
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(8)
                        }
                        .background(.secondary.opacity(0.3))
                        .cornerRadius(8)
                        
                    } else if let imageUrl = directMessage.imageUrl {
                        VStack {
                            AnimatedImage(url: imageUrl)
                                .placeholder {
                                    Color.secondary.opacity(0.2)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .imageScale(.large)
                                                .scaleEffect(3.0)
                                        )
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaledToFit()
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(directMessage.contentFormatted ?? "")
                        .foregroundColor(owner ? .white : Color(.label))
                        .tint(owner ? .white : .accentColor)
                    
                }
                .padding(8)
                .background(
                    owner ? Color.accentColor : Color(.systemGray5)
                )
                .cornerRadius(12)

            }
            
            if !owner {
                Spacer(minLength: 16)
            }

        }
        .textSelection(.enabled)
    }
}

struct DirectMessageView_Previews: PreviewProvider {
    static var previews: some View {
        DirectMessageView(userProfile: RUserProfile.preview)
            .environmentObject(NostrData.shared)
            .environmentObject(Navigation())
    }
}
