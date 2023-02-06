//
//  EncryptedMessageBubbleView.swift
//  Seer
//
//  Created by Jacob Davis on 2/6/23.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct EncryptedMessageBubbleView: View {
    
    @ObservedRealmObject var encryptedMessage: EncryptedMessage
    let owner: Bool
    
    var body: some View {
        HStack {
            
            if owner {
                Spacer(minLength: 16)
            }
            
            VStack(alignment: owner ? .trailing : .leading, spacing: 8) {
                Text(encryptedMessage.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack {
                    
//                    if let videoUrl = directMessage.videoUrl {
//
//                        VStack(spacing: 0) {
//                            AZVideoPlayer(player: AVPlayer(url: videoUrl))
//                                .frame(height: 200)
//                                .shadow(radius: 0)
//                            HStack {
//                                Image(systemName: "rectangle.and.hand.point.up.left.fill")
//                                    .font(.body)
//                                    .fontWeight(.regular)
//                                Text("Tap Image to watch video")
//                                //Spacer()
//                            }
//                            .font(.caption)
//                            .fontWeight(.bold)
//                            .padding(8)
//                        }
//                        .background(.secondary.opacity(0.3))
//                        .cornerRadius(8)
//
//                    } else if let imageUrl = directMessage.imageUrl {
//                        VStack {
//                            AnimatedImage(url: imageUrl)
//                                .placeholder {
//                                    Color.secondary.opacity(0.2)
//                                        .overlay(
//                                            Image(systemName: "photo")
//                                                .imageScale(.large)
//                                                .scaleEffect(3.0)
//                                        )
//                                }
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .scaledToFit()
//                                .cornerRadius(8)
//                        }
//                    }
                    
                    Text(encryptedMessage.contentFormatted ?? "")
//                        .foregroundColor(owner ? .white : Color(.labelColor))
//                        .tint(owner ? .white : .accentColor)
                    
                    
//                    Text(encryptedMessage.relayUrls.first ?? "")
//                        .foregroundColor(owner ? .white : Color(.label))
//                        .tint(owner ? .white : .accentColor)
                    
                }
                .padding(8)
                .background(
                    owner ? Color.accentColor.opacity(0.5) : Color(.textBackgroundColor).opacity(0.5)
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

struct EncryptedMessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TileBackground()
            List {
                EncryptedMessageBubbleView(encryptedMessage: .preview, owner: false)
                EncryptedMessageBubbleView(encryptedMessage: .preview, owner: true)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
