//
//  MacOSMessageDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

#if os(macOS)
import SwiftUI
import SwiftData
import SDWebImageSwiftUI
import Nostr

struct MacOSMessageDetailView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var selectedGroup: GroupVM?
    let messages: [ChatMessageVM]
    let groupMembers: [GroupMemberVM]
    let groupAdmins: [GroupAdminVM]
    let publicKeyMetadata: [PublicKeyMetadataVM]
    
    @Query private var ownerAccounts: [OwnerAccount]
    var selectedOwnerAccount: OwnerAccount? {
        return ownerAccounts.first(where: { $0.selected })
    }
    
    @State private var scroll: ScrollViewProxy?
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 32
    @FocusState private var inputFocused: Bool
    @State private var searchText = ""
    
    @State private var favoriteColor = 0
    
    @State private var infoPopoverPresented = false
    @State private var showTranslation: Bool = false
    
    @State private var replyMessage: ChatMessageVM?
    
    private let maxHeight : CGFloat = 350
    
    func getPublicKeyMetadata(forPublicKey publicKey: String) -> PublicKeyMetadataVM? {
        return publicKeyMetadata.first(where: { $0.publicKey == publicKey })
    }
    
    func getPubicKeyMetadata(forChatMessage chatMessage: ChatMessageVM?) -> PublicKeyMetadataVM? {
        guard let chatMessage else { return nil }
        return publicKeyMetadata.first(where: { $0.publicKey == chatMessage.publicKey })
    }
    
    func getReplyTo(forId id: String?) -> (chatMessage: ChatMessageVM, publicKeyMetadata: PublicKeyMetadataVM?)? {
        guard let chatMessage = messages.first(where: { $0.id == id }) else { return nil }
        return (chatMessage: chatMessage, publicKeyMetadata: getPubicKeyMetadata(forChatMessage: chatMessage))
    }
    
    var body: some View {
        
        ZStack {
            Image("tile_pattern_2")
                .resizable(resizingMode: .tile)
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [.clear, Color.secondary.opacity(0.2)]), startPoint: .bottom, endPoint: .top)
                )
            ScrollViewReader { reader in
                List(messages) { message in
                    MacOSMessageBubbleView(owner: message.publicKey == selectedOwnerAccount?.publicKey,
                                           chatMessage: message, publicKeyMetadata: getPublicKeyMetadata(forPublicKey: message.publicKey),
                                           replyTo: getReplyTo(forId: message.replyToEventId),
                                           showTranslation: $showTranslation)
                    .contextMenu(ContextMenu(menuItems: {
                        Button("Reply") {
                            withAnimation {
                                self.replyMessage = message
                                self.inputFocused = true
                            }
                        }
                        .disabled(selectedGroup == nil || !isMember())
                        
                        Button("Copy Text") {
                            appState.copyToClipboard(message.content)
                        }
                        
                        Button("Copy Event Id") {
                            appState.copyToClipboard(message.id)
                        }
                        
                        Divider()
                        
                        Button("Report") {
                            
                        }
                        .tint(.red)
                        
                    }))
                    
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: messages, initial: true, { oldValue, newValue in
                    if let last = messages.last {
                        scroll?.scrollTo(last.id, anchor: .top)
                    }
                })
                .onAppear {
                    scroll = reader
                    if let last = messages.last {
                        scroll?.scrollTo(last.id, anchor: .top)
                    }
                }
                
                if let replyMessage = replyMessage {
                    
                    LazyVStack {
                        HStack(spacing: 0) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .imageScale(.large)
                                .foregroundStyle(.accent)
                                .frame(width: 50, height: 50)
                            
                            Color
                                .accentColor
                                .frame(width: 2)
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading) {
                                Text(getPublicKeyMetadata(forPublicKey: replyMessage.publicKey)?.bestPublicName ?? replyMessage.publicKey)
                                    .font(.subheadline)
                                    .foregroundStyle(.accent)
                                    .bold()
                                Text(replyMessage.content)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: {
                                self.replyMessage = nil
                            }, label: {
                                Image(systemName: "xmark.circle")
                                    .imageScale(.large)
                            })
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing)
                    }
                    .background(.background)
                    .frame(height: 50)
                    .padding(.vertical, -8)
                    .transition(.move(edge: .bottom))
                    
                }
                
            }
        }
        .safeAreaInset(edge: .bottom) {
            if selectedGroup != nil && isMember() {
                ZStack(alignment: .leading) {
                    
                    Color(.textBackgroundColor)
                        .frame(height: max(0,textEditorHeight))
                    
                    Text(messageText)
                        .font(.system(.body))
                        .foregroundColor(.clear)
                        .padding()
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewHeightKey.self,
                                                   value: $0.frame(in: .local).size.height)
                        })
                    
                    TextEditor(text: $messageText)
                        .font(.system(.body))
                        .padding(.vertical)
                        .padding(.trailing, 50)
                        .padding(.leading)
                        .scrollDisabled(true)
                        .frame(height: max(0,textEditorHeight))
                        .onChange(of: messageText) { oldValue, newValue in
                            if let last = newValue.last {
                                if last == "\n" && !CGKeyCode.kVK_Shift.isPressed {
                                    guard let selectedOwnerAccount else { return }
                                    guard let selectedGroup else { return }
                                    withAnimation {
                                        if let replyMessage {
                                            appState.sendChatMessageReply(ownerAccount: selectedOwnerAccount, group: selectedGroup,
                                                                          withText: messageText.trimmingCharacters(in: .newlines),
                                                                          replyChatMessage: replyMessage)
                                           
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                self.replyMessage = nil
                                            }
                                            
                                        } else {
                                            appState.sendChatMessage(ownerAccount: selectedOwnerAccount,
                                                                     group: selectedGroup, withText: messageText.trimmingCharacters(in: .newlines))
                                        }
                                        
                                        messageText = ""
                                    }
                                }
                            }
                        }
                        .overlay(alignment: .top, content: {
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                                .frame(height: 1)
                                .shadow(radius: 3)
                        })
                        .overlay(alignment: .trailing) {
                            Button("😀") {
                                NSApp.orderFrontCharacterPalette($messageText)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding()
                        }
                        .focused($inputFocused)
                    
                }
                .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
                .keyboardShortcut(.return)
            }
            
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    
                    AnimatedImage(url: URL(string: selectedGroup?.picture ?? ""))
                        .transition(.fade)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .aspectRatio(contentMode: .fill)
                        .background(.gray)
                        .overlay {
                            if selectedGroup?.picture == nil {
                                Image(systemName: "rectangle.3.group.bubble")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 18))
                            }
                            
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    VStack(alignment: .leading) {
                        Text(selectedGroup?.name ?? "---")
                            .font(.headline)
                            .bold()
                        Text(selectedGroup?.relayUrl ?? "--")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(selectedGroup == nil ? 0.0 : 1.0)
                
                Spacer()
                
                if !isMember() && groupMembers.count > 0 {
                    
                    Button(action: {
                        guard let selectedOwnerAccount else { return }
                        guard let selectedGroup else { return }
                        appState.joinGroup(ownerAccount: selectedOwnerAccount, group: selectedGroup)
                    }) {
                        Text("Join")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .cornerRadius(6)
                }
                
                if let selectedGroup, let selectedOwnerAccount {
                    
                    ShareLink(item: selectedGroup.relayUrl + "'" + selectedGroup.id)
                        .fontWeight(.semibold)
                    
                    Button(action: { infoPopoverPresented = true }) {
                        Image(systemName: "info.circle")
                            .fontWeight(.semibold)
                            .offset(y: 1)
                    }
                    .popover(isPresented: $infoPopoverPresented, arrowEdge: .bottom, content: {
                        MacOSGroupInfoPopoverView(group: selectedGroup, members: groupMembers, admins: groupAdmins,
                                                  selectedOwnerAccount: selectedOwnerAccount)
                        .frame(width: 300, height: 400)
                    })
                }
                
            }
        }
        .onChange(of: selectedGroup) { oldValue, newValue in
            if oldValue != newValue {
                self.replyMessage = nil
            }
        }
    }
    
    func isMember() -> Bool {
        if groupMembers.count > 0 {
            if let selectedOwnerAccount {
                if  groupMembers.contains(where: { $0.publicKey == selectedOwnerAccount.publicKey }) {
                    return true
                }
            }
        }
        return false
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

import CoreGraphics

// Hacky shit to detect keydown.
// Why in the hell doesnt swiftui have this....Geeze
extension CGKeyCode {
    
    static let kVK_UpArrow: CGKeyCode = 0x7E
    static let kVK_Shift: CGKeyCode = 0x38

    var isPressed: Bool {
        CGEventSource.keyState(.combinedSessionState, key: self)
    }
}

//#Preview {
//    MacOSMessageDetailView(selectedGroup: .constant(nil), messages: [])
//}
#endif
