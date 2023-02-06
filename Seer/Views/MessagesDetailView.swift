//
//  MessagesDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 2/6/23.
//

import SwiftUI
import RealmSwift

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
                        withAnimation {
                            scroll?.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                })
                .onAppear {
                    scroll = reader
                }
                
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    if let last = encryptedMessages.last {
                        DispatchQueue.main.async {
                            withAnimation {
                                scroll?.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                }
                .padding()
            }

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
             }
            .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
            .keyboardShortcut(.return)
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
