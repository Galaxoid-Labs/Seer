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
                
                AvatarView(avatarUrl: publicKeyMetaData.picture, size: 40)
                
                VStack (alignment: .leading, spacing: 2) {
                    
                    HStack(spacing: 4) {
                        if let name = publicKeyMetaData.name, name.isValidName()  {
                            Text("@"+name)
                                .font(.system(.subheadline, weight: .bold))
                                .lineLimit(1)
                        }
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "key.fill")
                                .imageScale(.small)
                            Text(publicKeyMetaData.bech32PublicKey?.prefix(12) ?? "")
                        }
                        .lineLimit(1)
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(.secondary)
                        
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
