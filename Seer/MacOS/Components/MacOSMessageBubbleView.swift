//
//  MacOSMessageBubbleView.swift
//  Seer
//
//  Created by Jacob Davis on 6/12/24.
//

import SwiftUI
import SwiftData
import Translation

struct MacOSMessageBubbleView: View {
    
    let owner: Bool
    @Bindable var eventMessage: EventMessage
    @State private var publicKeyMetadata: PublicKeyMetadata?
//    @Query var counters: [PublicKeyMetadata] 
//    var counter: PublicKeyMetadata? { counters.first(where: { $0.publicKey == eventMessage.publicKey })}
    @State private var showTranslation: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            
            if !owner {
                AvatarView(avatarUrl: publicKeyMetadata?.picture ?? "", size: 40)
                    .offset(y: 8)
            }
            
            LazyVStack(alignment: owner ? .trailing : .leading, spacing: 6) {
                
                if !owner {
                    HStack {
                                            
                        Text(publicKeyMetadata?.name ?? eventMessage.publicKey.prefix(12).lowercased())
                            .bold()
                            .padding(.leading, 8)
                        
                        if let nip05 = publicKeyMetadata?.nip05 { // TODO: Check nip verified
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.seal.fill")
                                    .imageScale(.small)
                                    .foregroundStyle(.accent)
                                
                                Text(verbatim: nip05)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    }
                }
                
                VStack {
                    Text(eventMessage.contentFormatted ?? "")
                        .foregroundStyle(.white)
                }
                .padding(8)
                .background(owner ? Color.accentColor : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(owner ? .leading : .trailing, 150)
                .translationPresentation(isPresented: $showTranslation,
                                         text: eventMessage.content ?? "")
                .onLongPressGesture {
                    showTranslation = true
                }

            }
            
        }
        .listRowSeparator(.hidden, edges: .all)
        .padding(.bottom, 12)
    }
}

#Preview {
    
    let container = PreviewData.container
    let messageA = EventMessage(id: "abc", relayUrl: "wss://groups.fiatjaf.com", publicKey: "e958cd75b9546e8ad2ebc096816be5a8bc22a75702257838a47ef848dd2dd03a", createdAt: .now.addingTimeInterval(-6000), groupId: "016fb665", content: "Hey! Whats going on?")
    
    return ZStack {
        Image("tile_pattern_2")
            .resizable(resizingMode: .tile)
            //.colorMultiply(Color("Secondary"))
            .opacity(0.1)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                LinearGradient(gradient: Gradient(colors: [.clear, Color("Secondary").opacity(0.1)]), startPoint: .top, endPoint: .bottom)
            )
        
        List {
            MacOSMessageBubbleView(owner: false, eventMessage: messageA)
                .modelContainer(container)
                .environmentObject(AppState.shared)
            
            MacOSMessageBubbleView(owner: true, eventMessage: messageA)
                .modelContainer(container)
                .environmentObject(AppState.shared)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        
    }

}
