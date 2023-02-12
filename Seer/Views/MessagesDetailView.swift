//
//  MessagesDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 2/6/23.
//

import SwiftUI
import RealmSwift
import NostrKit

struct MessagesDetailView: View {
    
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var appState: AppState
    
    @ObservedResults(EncryptedMessage.self) var encryptedMessageResults
    
    var encryptedMessages: [EncryptedMessage] {
        guard let ownerKey = navigation.contentValue.ownerKey else { return [] }
        guard let publicKeyMetaData = navigation.contentValue.publicKeyMetaData else { return [] }
        return encryptedMessageResults
            .filter({ ($0.publicKey == ownerKey.publicKey && $0.toPublicKey == publicKeyMetaData.publicKey) ||
                $0.toPublicKey == ownerKey.publicKey && $0.publicKey == publicKeyMetaData.publicKey
            })
            .sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    @State private var scroll: ScrollViewProxy?
    
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 32
    @FocusState private var inputFocused: Bool
    
    private let maxHeight : CGFloat = 350
    
    var body: some View {
        ZStack {
            TileBackground()
            ScrollViewReader { reader in
                List {
                    ForEach(encryptedMessages) { encryptedMessage in
                        let owner = navigation.contentValue.ownerKey?.publicKey != encryptedMessage.toPublicKey
                        EncryptedMessageBubbleView(encryptedMessage: encryptedMessage, owner: owner)
                            .id(encryptedMessage.id)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: navigation.contentValue, perform: { newValue in
                    if let last = encryptedMessages.last {
                        scroll?.scrollTo(last.id, anchor: .top)
                    }
                })
                .onAppear {
                    scroll = reader
                    if let last = encryptedMessages.last {
                        scroll?.scrollTo(last.id, anchor: .top)
                    }
                }
                
            }
//            .overlay(alignment: .bottomTrailing) {
//                Button(action: {
//                    if let last = encryptedMessages.last {
//                        DispatchQueue.main.async {
//                            withAnimation {
//                                scroll?.scrollTo(last.id, anchor: .top)
//                            }
//                        }
//                    }
//                }) {
//                    Image(systemName: "arrow.down.circle.fill")
//                }
//                .padding()
//            }

        }
        .safeAreaInset(edge: .bottom) {
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
                    .padding()
                    .scrollDisabled(true)
                    .frame(height: max(0,textEditorHeight))
                    .onChange(of: messageText) { newValue in
                        if let last = newValue.last {
                            if last == "\n" && !CGKeyCode.kVK_Shift.isPressed {
                                send(withText: messageText.trimmingCharacters(in: .newlines))
                                messageText = ""
                            }
                        }
                    }

             }
            .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
            .keyboardShortcut(.return)
        }
    }
    
    func send(withText: String) {
        if !withText.isEmpty && withText != "\n" {
            
            guard let ownerKey = navigation.contentValue.ownerKey else { return }
            guard let publicKeyMetaData = navigation.contentValue.publicKeyMetaData else { return }
            guard let keypair = ownerKey.getKeyPair() else { return }
            guard let encryptedMessage = KeyPair.encryptDirectMessageContent(withPrivatekey: keypair.privateKey, pubkey: publicKeyMetaData.publicKey, content: withText) else { return }
            let tag = EventTag.pubKey(publicKey: publicKeyMetaData.publicKey)
            guard let event = try? Event(keyPair: keypair, kind: .encryptedDirectMessage, tags: [tag], content: encryptedMessage) else { return }
            
            
            for relay in appState.relays {
                relay.publish(event: event)
            }
            
            
            
            
            
//            if nostrData.createEncyrpedDirectMessageEvent(withContent: messageText, forPublicKey: userProfile.publicKey) {
//                withAnimation {
//                    messageText = ""
//                    inputFocused = false
//                }
//            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

struct MessagesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesDetailView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
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
