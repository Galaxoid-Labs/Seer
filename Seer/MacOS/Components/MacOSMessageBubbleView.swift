//
//  MacOSMessageBubbleView.swift
//  Seer
//
//  Created by Jacob Davis on 6/12/24.
//

#if os(macOS)
import SwiftUI
import SwiftData
import SDWebImageSwiftUI
import Translation

struct MacOSMessageBubbleView: View {
    
    let owner: Bool
    let chatMessage: ChatMessageVM
    let publicKeyMetadata: PublicKeyMetadataVM?
    let replyTo: (chatMessage: ChatMessageVM, publicKeyMetadata: PublicKeyMetadataVM?)?
    @Binding var showTranslation: Bool
    
//    func getReplyBackgroundColor() -> Color {
//        if owner {
//            return .accentColor.brightness(/*@START_MENU_TOKEN@*/0.60/*@END_MENU_TOKEN@*/)
//        }
//    }
    
    var body: some View {
        HStack(alignment: .top) {
            
            if !owner {
                AvatarView(avatarUrl: publicKeyMetadata?.picture ?? "", size: 40)
                    .offset(y: 8)
            }
            
            LazyVStack(alignment: owner ? .trailing : .leading, spacing: 6) {
                
                if !owner {
                    HStack {
                                            
                        Text(publicKeyMetadata?.name ?? chatMessage.publicKey.prefix(12).lowercased())
                            .bold()
                            .padding(.leading, 8)
                        
                        if let nip05 = publicKeyMetadata?.nip05 { // TODO: Check nip verified
                            HStack(spacing: 2) {
//                                if publicKeyMetadata?.nip05Verified {
//                                    Image(systemName: "checkmark.seal.fill")
//                                        .imageScale(.small)
//                                        .foregroundStyle(.accent)
//                                }

                    
                                Text(verbatim: nip05)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    }
                }
                
                VStack(alignment: .leading) {
                    
                    if let replyTo {
                        
                        HStack(spacing: 0) {
                            Color
                                .white
                                .frame(width: 3)

                            VStack(alignment: .leading) {
                                Text(replyTo.publicKeyMetadata?.bestPublicName ?? replyTo.chatMessage.publicKey)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .bold()
                                Text(replyTo.chatMessage.content)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .padding(4)
                            //.padding(.horizontal)
                            
                        }
                        .background((owner ? Color.accentColor : .gray).brightness(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                    }
                    
                    Text(chatMessage.contentFormated)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                    
                    ForEach(chatMessage.imageUrls, id: \.self) { image in
                        AnimatedImage(url: image, placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 40))
                        })
                        .resizable()
                        //.frame(width: 100, height: 100)
                        .aspectRatio(contentMode: .fill)
                        .background(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(8)
                .background(owner ? Color.accentColor : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(owner ? .leading : .trailing, 150)
                .translationPresentation(isPresented: $showTranslation,
                                         text: chatMessage.content)
                .onLongPressGesture {
                    showTranslation = true
                }
                //.frame(maxWidth: 400)
                
                if let links = chatMessage.urls["links"] {
                    ForEach(links, id: \.self) { link in
                        
                        Link(destination: link) {
                            LinkPreviewView(owner: owner, viewModel: .init(link.absoluteString))
                        }
                        .buttonStyle(.plain)

                    }
                }
                
                Text(chatMessage.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            
        }
        .listRowSeparator(.hidden, edges: .all)
        .padding(.bottom, 12)
    }
}

//#Preview {
//    
////    let container = PreviewData.container
////    let messageA = EventMessage(id: "abc", relayUrl: "wss://groups.fiatjaf.com", publicKey: "e958cd75b9546e8ad2ebc096816be5a8bc22a75702257838a47ef848dd2dd03a", createdAt: .now.addingTimeInterval(-6000), groupId: "016fb665", content: "Hey! Whats going on? https://www.autosport.com https://galaxoidlabs.com https://opensats.org/blog/bitcoin-grants-july-2024")
////    
////    return ZStack {
////        Image("tile_pattern_2")
////            .resizable(resizingMode: .tile)
////            //.colorMultiply(Color("Secondary"))
////            .opacity(0.1)
////            .edgesIgnoringSafeArea(.all)
////            .overlay(
////                LinearGradient(gradient: Gradient(colors: [.clear, Color("Secondary").opacity(0.1)]), startPoint: .top, endPoint: .bottom)
////            )
////        
////        List {
////            MacOSMessageBubbleView(owner: false, eventMessage: messageA)
////                .modelContainer(container)
////                .environmentObject(AppState.shared)
////            
////            MacOSMessageBubbleView(owner: true, eventMessage: messageA)
////                .modelContainer(container)
////                .environmentObject(AppState.shared)
////        }
////        .listStyle(.plain)
////        .scrollContentBackground(.hidden)
////        
////    }
//
//}
#endif
