//
//  RootEncryptedMessageView.swift
//  Seer
//
//  Created by Jacob Davis on 2/5/23.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct RootEncryptedMessageView: View {
    
    @ObservedRealmObject var publicKeyMetaData: PublicKeyMetaData

    var body: some View {
        HStack {
            
            VStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 8, height: 8)
            .padding(4)
            .opacity(publicKeyMetaData.hasUnreadMessages() ? 1.0 : 0.0)
            
            HStack(alignment: .top, spacing: 12) {
                
                if publicKeyMetaData.picture.isEmpty {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 40))
                } else {
                    AvatarView(avatarUrl: publicKeyMetaData.picture, size: 40)
                }
                
                
                VStack (alignment: .leading, spacing: 2) {
                    
                    HStack(spacing: 4) {
                        
                        HStack(spacing: 4) {
                            Text(publicKeyMetaData.bestPublicName)
                                .font(.system(.subheadline, weight: .bold))
                                .lineLimit(1)
                            if publicKeyMetaData.nip05Verified {
                                ZStack {
                                    Circle()
                                        .frame(width: 10)
                                        .foregroundColor(.white)
                                    Image(systemName: "checkmark.seal.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.white)
                                    Image(systemName: "checkmark.seal.fill")
                                        .imageScale(.medium)
                                        .foregroundColor(.accentColor)
                                }

                            }
                        }

                        Spacer()
                        Text((publicKeyMetaData.getLatestMessage()?.createdAt ?? .now), style: .offset)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Text(publicKeyMetaData.getLatestMessage()?.decryptContent() ?? "Not sure?")
                        .font(.callout)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                    
                }
                .contentShape(Rectangle())
            }
            
        }
        .padding(.vertical, 8)

    }
}

struct RootEncryptedMessageView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            RootEncryptedMessageView(publicKeyMetaData: .preview)
            RootEncryptedMessageView(publicKeyMetaData: .preview)
            RootEncryptedMessageView(publicKeyMetaData: .preview)
        }
    }
}
