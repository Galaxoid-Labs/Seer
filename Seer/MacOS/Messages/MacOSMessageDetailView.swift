//
//  MacOSMessageDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 6/13/24.
//

import SwiftUI
import SwiftData
import Nostr

struct MacOSMessageDetailView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var selectedGroup: SimpleGroup?
   
    @Query private var ownerAccounts: [OwnerAccount]
    var currentOwnerAccount: OwnerAccount? {
        return ownerAccounts.first(where: { $0.selected })
    }
    
    @Query private var eventMessages: [EventMessage]
    var messages: [EventMessage] {
        return eventMessages.filter({ $0.groupId == selectedGroup?.id ?? ""}).sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    @State private var scroll: ScrollViewProxy?
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 32
    @FocusState private var inputFocused: Bool
    
    private let maxHeight : CGFloat = 350
    
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
                    MacOSMessageBubbleView(owner: message.publicKey == "c5cfda98d01f152b3493d995eed4cdb4d9e55a973925f6f9ea24769a5a21e778", eventMessage: message)
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
            }
        }
//        .overlay(alignment: .top, content: {
//            Rectangle()
//                .fill(.white)
//                .frame(height: 40)
//                .offset(y: -40)
//        })
        .safeAreaInset(edge: .bottom) {
            if selectedGroup != nil {
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
                                    send(withText: messageText.trimmingCharacters(in: .newlines))
                                    messageText = ""
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
                Spacer()
//                HStack {
//                    Button(action: { print("Add tapped") }) {
//                        Image(systemName: "plus")
//                    }
//                    
//                    Button(action: { print("Edit tapped") }) {
//                        Image(systemName: "pencil")
//                    }
//                    
//                    Button(action: { print("Share tapped") }) {
//                        Image(systemName: "square.and.arrow.up")
//                    }
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .fontWeight(.semibold)
                        .offset(y: 1)
                }

//                    
//                    Menu {
//                        Button("Compact", action: { print("Delete tapped") })
//                    } label: {
//                        Image(systemName: "ellipsis.circle")
//                    }
//                }
//                .padding(.horizontal, 6)
//                .padding(.vertical, 2)
//                .background(.thickMaterial)
//                .clipShape(Capsule())
            }
        }
    }
    
    func send(withText text: String) {
        guard let currentOwnerAccount else { return }
        guard let key = currentOwnerAccount.getKeyPair() else { return }
        guard let relayUrl = selectedGroup?.relayUrl else { return }
        guard let groupId = selectedGroup?.id else { return }
    
        var event = Event(pubkey: currentOwnerAccount.publicKey, createdAt: .init(), kind: .custom(9), tags: [Tag(id: "h", otherInformation: groupId)], content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
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

#Preview {
    MacOSMessageDetailView(selectedGroup: .constant(nil))
}
