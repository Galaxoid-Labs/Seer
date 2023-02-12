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
    
    var filteredPublicKeyMetaData: [PublicKeyMetaData] {
        guard let ownerKey = navigation.sidebarValue.ownerKey else { return [] }
        return Array(Set(Array(encryptedMessageResults
            .filter({ $0.publicKey == ownerKey.publicKey || $0.toPublicKey == ownerKey.publicKey })
            .compactMap({ $0.getOtherPublicMetaData(whereOwnerKey: ownerKey) }))))
            .sorted(by: { $0.getLatestMessage()?.createdAt ?? .now > $1.getLatestMessage()?.createdAt ?? .now })
    }
    
    var body: some View {
        ZStack {
            if filteredPublicKeyMetaData.count > 0 {
                List(filteredPublicKeyMetaData, selection: $navigation.contentValue) { publicKeyMetaData in
                    NavigationLink(value: Navigation.ContentValue(publicKeyMetaData: publicKeyMetaData,
                                                                  ownerKey: navigation.sidebarValue.ownerKey)) {
                        RootEncryptedMessageView(publicKeyMetaData: publicKeyMetaData)
                    }
                }
            } else {
                Text("No messages...")
            }
        }
        .navigationSplitViewColumnWidth(350)
    }
}

struct MessagesContentView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesContentView()
            .environmentObject(Navigation())
            .environmentObject(AppState.shared)
    }
}
