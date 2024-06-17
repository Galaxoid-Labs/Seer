//
//  PreviewData.swift
//  Seer
//
//  Created by Jacob Davis on 4/18/24.
//

import Foundation
import SwiftData

@MainActor
class PreviewData {
    static let container: ModelContainer = {
        do {
            let schema = Schema([
                OwnerAccount.self,
                PublicKeyMetadata.self,
                Relay.self,
                SimpleGroup.self,
                EventMessage.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: modelConfiguration)
            
            // Create data for previews
            // Key      => nsec17e46mrxmnj5sdyrh5h98sw3urmplwv7lycj9jn5y7zjmc8yyh07qpf9wlj
            // PubHex   => 8c92b6ca939ba1faa8a2b1186cc12513aaf2d6b353b41bdec1ed6c69b2cd4fa8
            let ownerAccountA = OwnerAccount.restore(withPrivateKeyHexOrNsec: "nsec17e46mrxmnj5sdyrh5h98sw3urmplwv7lycj9jn5y7zjmc8yyh07qpf9wlj")!
            let publicKeyMetadataA = PublicKeyMetadata(publicKey: "8c92b6ca939ba1faa8a2b1186cc12513aaf2d6b353b41bdec1ed6c69b2cd4fa8", 
                                                       bech32PublicKey: ownerAccountA.getKeyPair()?.bech32PublicKey ?? "", 
                                                       name: "Satoshi", nip05: "satoshi@bitcoin.com", createdAt: .now, nip05Verified: true)
            ownerAccountA.publicKeyMetadata = publicKeyMetadataA
            
            // Key      => nsec1j4ueeha05d6pgxtudfs59s3xf408e49c5w6uqd7lxv46wh39pdlqjp8e27
            // PubHex   => e958cd75b9546e8ad2ebc096816be5a8bc22a75702257838a47ef848dd2dd03a
            let ownerAccountB = OwnerAccount.restore(withPrivateKeyHexOrNsec: "nsec1j4ueeha05d6pgxtudfs59s3xf408e49c5w6uqd7lxv46wh39pdlqjp8e27")!
            let publicKeyMetadataB = PublicKeyMetadata(publicKey: "e958cd75b9546e8ad2ebc096816be5a8bc22a75702257838a47ef848dd2dd03a",
                                                       bech32PublicKey: ownerAccountB.getKeyPair()?.bech32PublicKey ?? "", name: "Cool Dude", createdAt: .now, nip05Verified: false)
            ownerAccountB.publicKeyMetadata = publicKeyMetadataB

            container.mainContext.insert(ownerAccountA)
            container.mainContext.insert(ownerAccountB)
            
            let relayA = Relay(url: "wss://groups.fiatjaf.com", name: "groups", desc: "a test relay for nip-29 groups", publicKey: "1dd006bd6ba37059b321ec648e606e498bab6db110a11ab85b075b8287726ffd", contact: "", supportedNips: [1,11,70,29])
            //let relayB = Relay(url: "wss://relay.nostr.band", name: "Nostr.Band Relay", desc: "This is a fast relay with full archive of textual posts", publicKey: "818a39b5f164235f86254b12ca586efccc1f95e98b45cb1c91c71dc5d9486dda", contact: "mailto:admin@nostr.band", supportedNips: [1,11,12,15,20,33,45,50])

            container.mainContext.insert(relayA)
            //container.mainContext.insert(relayB)
            
            let simpleGroupA = SimpleGroup(id: "016fb665", relayUrl: "wss://groups.fiatjaf.com", name: "General", isPublic: true, isOpen: true)
            container.mainContext.insert(simpleGroupA)
            
            let simpleGroupB = SimpleGroup(id: "216fb665", relayUrl: "wss://groups.fiatjaf.com", name: "Pizza", isPublic: true, isOpen: true)
            container.mainContext.insert(simpleGroupB)
            
            let messageA = EventMessage(id: "abc", relayUrl: "wss://groups.fiatjaf.com", publicKey: "e958cd75b9546e8ad2ebc096816be5a8bc22a75702257838a47ef848dd2dd03a", createdAt: .now.addingTimeInterval(-6000), groupId: "016fb665", content: "Hey! Whats going on?")
            container.mainContext.insert(messageA)
            
            let messageB = EventMessage(id: "abcef", relayUrl: "wss://groups.fiatjaf.com", publicKey: "8c92b6ca939ba1faa8a2b1186cc12513aaf2d6b353b41bdec1ed6c69b2cd4fa8", createdAt: .now, groupId: "016fb665", content: "I dont know?")
            container.mainContext.insert(messageB)

            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
}
