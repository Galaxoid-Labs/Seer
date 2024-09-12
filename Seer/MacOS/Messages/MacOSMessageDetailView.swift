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
    
    let relayUrl: String
    let groupId: String
    
    @Query private var allMessages: [ChatMessage]
    @Query var groupMembers: [GroupMember]
    @Query var groupAdmins: [GroupAdmin]
    
    var chatMessages: [ChatMessage] {
        return Array(allMessages.suffix(appState.chatMessageNumResults))
    }
    
    @State private var scroll: ScrollViewProxy?
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 32
    @State private var searchText = ""
    @State private var infoPopoverPresented = false
    @State private var showTranslation: Bool = false
    @State private var replyMessage: ChatMessage?
    
    @FocusState private var inputFocused: Bool

    private let maxHeight : CGFloat = 350
    
    init(relayUrl: String, groupId: String, chatMessageNumResults: Binding<Int>) {
        self.relayUrl = relayUrl
        self.groupId = groupId
        _groupMembers = Query(filter: GroupMember.predicate(byGroupId: groupId, relayUrl: relayUrl))
        _groupAdmins = Query(filter: GroupAdmin.predicate(byGroupId: groupId, relayUrl: relayUrl))
        _allMessages = Query(filter: ChatMessage.predicate(byGroupId: groupId, relayUrl: relayUrl),
                             sort: [SortDescriptor(\.createdAt, order: .forward)], animation: .interactiveSpring)
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
                List(chatMessages) { message in
                    MacOSMessageBubbleView(owner: message.publicKey == appState.selectedOwnerAccount?.publicKey,
                                           chatMessage: message,
                                           showTranslation: $showTranslation)
                    .transition(.move(edge: .bottom))
                    .id(message.id)
                    .contextMenu(ContextMenu(menuItems: {
                        Button("Reply") {
                            withAnimation {
                                self.replyMessage = message
                                self.inputFocused = true
                                if let last = chatMessages.last {
                                    self.scroll?.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .disabled(appState.selectedGroup == nil || !isMemberOrAdmin())
                        
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
                .onChange(of: chatMessages, initial: true, { oldValue, newValue in
                    if let last = chatMessages.last {
                        scroll?.scrollTo(last.id, anchor: .bottom)
                    }
                })
                .onAppear {
                    scroll = reader
                    if let last = chatMessages.last {
                        scroll?.scrollTo(last.id, anchor: .bottom)
                    }
                }
                
                if let replyMessage = replyMessage {
                    
                    LazyVStack {
                        HStack(spacing: 0) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .imageScale(.large)
                                .foregroundStyle(.accent)
                                .frame(width: 50, height: 50)
                                .transition(.move(edge: .bottom))
                            
                            Color
                                .accentColor
                                .frame(width: 2)
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading) {
                                Text(replyMessage.publicKeyMetadata?.bestPublicName ?? replyMessage.publicKey)
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
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            //if appState.selectedGroup != nil && isMemberOrAdmin() {
            
            HStack(spacing: 8) {
                
                TextField("Write something", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .onSubmit(of: .text, {
                        if CGKeyCode.kVK_Shift.isPressed {
                            messageText += "\n"
                        } else {
                            guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                            guard let selectedGroup = appState.selectedGroup else { return }
                            if let replyMessage {
                                let text = messageText.trimmingCharacters(in: .newlines)
                                let reply = replyMessage
                                Task {
                                    await appState.sendChatMessageReply(ownerAccount: selectedOwnerAccount, group: selectedGroup,
                                                                  withText: text,
                                                                        replyChatMessage: reply)
                                    
                                    if let last = chatMessages.last {
                                        self.scroll?.scrollTo(last.id, anchor: .bottom)
                                    }
                                }

                                self.replyMessage = nil
                                messageText = ""

                            } else {
                                let text = messageText.trimmingCharacters(in: .newlines)
                                Task {
                                    await appState.sendChatMessage(ownerAccount: selectedOwnerAccount,
                                                                   group: selectedGroup, withText: text)
                                    
                                    if let last = chatMessages.last {
                                        self.scroll?.scrollTo(last.id, anchor: .bottom)
                                    }
                                    
                                }
                                messageText = ""
                            }
                        }
                    })
                    .padding(.leading, 12)
                    .padding(.trailing, 16)
                    .padding(.vertical, 8)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: .init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.6))
                    )
                    .overlay(alignment: .trailing) {
                        Button("", systemImage: "face.smiling") {
                            Task {
                                NSApp.orderFrontCharacterPalette($messageText) // TODO: Fix where this comes up
                            }
                        }
                        .buttonStyle(.plain)
                        .imageScale(.large)
                    }
                    .focused($inputFocused)

            }
            .padding(.horizontal)
            .padding(.vertical)
            .background(
                .background
            )
            .overlay(alignment: .top) {
                Color.secondary.opacity(0.3)
                    .frame(height: 1)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    
                    AnimatedImage(url: URL(string: appState.selectedGroup?.picture ?? ""))
                        .transition(.fade)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .aspectRatio(contentMode: .fill)
                        .background(.gray)
                        .overlay {
                            if appState.selectedGroup?.picture == nil {
                                Image(systemName: "rectangle.3.group.bubble")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 18))
                            }
                            
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    VStack(alignment: .leading) {
                        Text(appState.selectedGroup?.name ?? "---")
                            .font(.headline)
                            .bold()
                        Text(appState.selectedGroup?.relayUrl ?? "--")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(appState.selectedGroup == nil ? 0.0 : 1.0)
                
                Spacer()
                
                if !isMemberOrAdmin() && groupMembers.count > 0 {
                    
                    Button(action: {
                        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                        guard let selectedGroup = appState.selectedGroup else { return }
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
                
                if let selectedGroup = appState.selectedGroup, let selectedOwnerAccount = appState.selectedOwnerAccount {
                   
                    if appState.chatMessageNumResults < allMessages.count {
                        Button(action: {
                            appState.chatMessageNumResults *= 2
                        }) {
                            Text("Load More")
                                //.foregroundStyle(.white)
                        }
                    }
                    
                    ShareLink(item: selectedGroup.relayUrl + "'" + selectedGroup.id)
                        .fontWeight(.semibold)
                    
                    Button(action: { infoPopoverPresented = true }) {
                        Image(systemName: "info.circle")
                            .fontWeight(.semibold)
                            .offset(y: 1)
                    }
                    .popover(isPresented: $infoPopoverPresented, arrowEdge: .bottom, content: {
                        MacOSGroupInfoPopoverView(group: selectedGroup, members: groupMembers, 
                                                  admins: groupAdmins,
                                                  selectedOwnerAccount: selectedOwnerAccount)
                        .frame(width: 300, height: 400)
                    })
                }
                
            }
        }
        .onChange(of: appState.selectedGroup) { oldValue, newValue in
            if oldValue != newValue {
                self.replyMessage = nil
            }
        }
    }
    
    func isMemberOrAdmin() -> Bool {
        if let selectedGroup = appState.selectedGroup {
            return selectedGroup.isMember || selectedGroup.isAdmin
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
