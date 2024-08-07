//
//  MacOSMessageDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

#if os(macOS)
import SwiftUI
import SwiftData
import Nostr

struct MacOSMessageDetailView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var selectedGroup: GroupVM?
    let messages: [ChatMessageVM]
    let groupMembers: [GroupMemberVM]
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
    
    private let maxHeight : CGFloat = 350
    
    func getPublicKeyMetadata(forPublicKey publicKey: String) -> PublicKeyMetadataVM? {
        return publicKeyMetadata.first(where: { $0.publicKey == publicKey })
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
                    MacOSMessageBubbleView(owner: message.publicKey == selectedOwnerAccount?.publicKey, chatMessage: message, publicKeyMetadata: getPublicKeyMetadata(forPublicKey: message.publicKey))
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
                    //print(messages.count)
                }
            }
        }
//        .overlay(alignment: .top, content: {
//            Rectangle()
//                .fill(.white)
//                .frame(height: 40)
//                .offset(y: -40)
//        })
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
                        .onChange(of: messageText) { newValue in
                            if let last = newValue.last {
                                if last == "\n" && !CGKeyCode.kVK_Shift.isPressed {
                                    withAnimation {
                                        send(withText: messageText.trimmingCharacters(in: .newlines))
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
                VStack(alignment: .leading) {
                    Text(selectedGroup?.name ?? "---")
                        .font(.headline)
                        .bold()
                    Text(selectedGroup?.relayUrl ?? "--")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(selectedGroup == nil ? 0.0 : 1.0)

                Spacer()
                
                if !isMember() && groupMembers.count > 0 {
                    
                    Button(action: {
                        join()
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
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .fontWeight(.semibold)
                        .offset(y: 1)
                }
            }
        }
    }
    
    func join() {
        guard let selectedOwnerAccount else { return }
        guard let key = selectedOwnerAccount.getKeyPair() else { return }
        guard let relayUrl = selectedGroup?.relayUrl else { return }
        guard let groupId = selectedGroup?.id else { return }
        var joinEvent = Event(pubkey: selectedOwnerAccount.publicKey, createdAt: .init(), kind: .groupJoinRequest,
                          tags: [Tag(id: "h", otherInformation: groupId)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        appState.nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    func leave() {
        guard let selectedOwnerAccount else { return }
        guard let key = selectedOwnerAccount.getKeyPair() else { return }
        guard let relayUrl = selectedGroup?.relayUrl else { return }
        guard let groupId = selectedGroup?.id else { return }
        var joinEvent = Event(pubkey: selectedOwnerAccount.publicKey, createdAt: .init(), kind: .groupRemoveUser,
                              tags: [Tag(id: "h", otherInformation: groupId), Tag(id: "p", otherInformation: selectedOwnerAccount.publicKey)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        appState.nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
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
    
    func send(withText text: String) {
        guard let selectedOwnerAccount else { return }
        guard let key = selectedOwnerAccount.getKeyPair() else { return }
        guard let relayUrl = selectedGroup?.relayUrl else { return }
        guard let groupId = selectedGroup?.id else { return }
    
        var event = Event(pubkey: selectedOwnerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
                          tags: [Tag(id: "h", otherInformation: groupId)], content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
//        var joinEvent = Event(pubkey: currentOwnerAccount.publicKey, createdAt: .init(), kind: .groupJoinRequest,
//                          tags: [Tag(id: "h", otherInformation: groupId)], content: "")
//        
//        do {
//            try joinEvent.sign(with: key)
//        } catch {
//            print(error.localizedDescription)
//        }
//
//        appState.nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
        appState.nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
        
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
