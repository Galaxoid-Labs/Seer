//
//  MessagesContentView.swift
//  Seer
//
//  Created by Jacob Davis on 2/6/23.
//

import SwiftUI
import RealmSwift

struct MessagesContentView: View {
    
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var appState: AppState
    
    @ObservedResults(PublicKeyMetaData.self) var publicKeyMetaDataResults
    @ObservedResults(EncryptedMessage.self) var encryptedMessageResults
    
    var inboxData: [PublicKeyMetaData] {
        guard let ownerKey = navigation.sidebarValue.ownerKey else { return [] }
        let messages = encryptedMessageResults
            .filter({ $0.publicKey == ownerKey.publicKey || $0.toPublicKey == ownerKey.publicKey })
        let uniquePublicKeyMetaData = Set(messages
            .compactMap({ $0.getOtherPublicMetaData(whereOwnerKey: ownerKey) }))
            .filter({ $0.hasBeenContactBy(ownerKey: ownerKey) })
        return Array(uniquePublicKeyMetaData)
            .sorted(by: { $0.getLatestMessage()?.createdAt ?? .now > $1.getLatestMessage()?.createdAt ?? .now })
    }
    
    var unknownData: [PublicKeyMetaData] {
        guard let ownerKey = navigation.sidebarValue.ownerKey else { return [] }
        let messages = encryptedMessageResults
            .filter({ $0.publicKey == ownerKey.publicKey || $0.toPublicKey == ownerKey.publicKey })
        let uniquePublicKeyMetaData = Set(messages
            .compactMap({ $0.getOtherPublicMetaData(whereOwnerKey: ownerKey) }))
            .filter({ $0.hasBeenContactBy(ownerKey: ownerKey) == false })
        return Array(uniquePublicKeyMetaData)
            .sorted(by: { $0.getLatestMessage()?.createdAt ?? .now > $1.getLatestMessage()?.createdAt ?? .now })
    }
    
    var body: some View {
        ZStack {
            
            switch navigation.sidebarValue.filter {
            case "inbox":
                if inboxData.count > 0 {
                    List(inboxData, selection: $navigation.contentValue) { publicKeyMetaData in
                        NavigationLink(value: Navigation.ContentValue(publicKeyMetaData: publicKeyMetaData,
                                                                      ownerKey: navigation.sidebarValue.ownerKey)) {
                            RootEncryptedMessageView(publicKeyMetaData: publicKeyMetaData)
                        }
                    }
                } else {
                    Text("No messages...")
                }
            case "unknown":
                if unknownData.count > 0 {
                    List(unknownData, selection: $navigation.contentValue) { publicKeyMetaData in
                        NavigationLink(value: Navigation.ContentValue(publicKeyMetaData: publicKeyMetaData,
                                                                      ownerKey: navigation.sidebarValue.ownerKey)) {
                            RootEncryptedMessageView(publicKeyMetaData: publicKeyMetaData)
                        }
                    }
                } else {
                    Text("No messages...")
                }
            default: Text("No messages...")
            }
            
        }
        .navigationSplitViewColumnWidth(400)
    }
}

struct MessagesContentView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesContentView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
    }
}
