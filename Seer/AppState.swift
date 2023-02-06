//
//  AppState.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import Foundation
import RealmSwift
import KeychainAccess

class AppState: ObservableObject {
    
    var relays: Set<RelayConnection> = []

    static let shared = AppState()
    
    let realm: Realm
    
    private init() {
        var config = Realm.Configuration(schemaVersion: 3)
        config.deleteRealmIfMigrationNeeded = true
        Realm.Configuration.defaultConfiguration = config
        self.realm = try! Realm()
        self.bootstrapRelays()
//        realm.writeAsync {
//            self.realm.deleteAll()
//        }
//        print(Keychain(service: "seer").allKeys())
    }
    
    func bootstrapRelays() {
        if self.realm.objects(Relay.self).count == 0 {
            try? realm.write {
                self.realm.add(Relay.bootstrap())
            }
        }
        Task {
            await updateRelayInformationForAll()
        }
    }
    
    func createNewOwnerKey() {
        if let ownerKey = OwnerKey.createNew() {
            try? realm.write {
                self.realm.add(ownerKey)
                self.realm.add(PublicKeyMetaData.create(withPublicKey: ownerKey.publicKey))
            }
            Task {
                await connectRelays()
            }
        }
    }
    
    @MainActor
    func connectRelays() async {
        self.relays = Set(Array(self.realm.objects(Relay.self)).map({ RelayConnection(relayUrl: $0.url) }))
        for relay in relays {
            relay.connect()
        }
    }
    
    @MainActor
    func tryImport(withPrivateKey privateKey: String) async -> Bool {
        if let keyPair = OwnerKey.keyPairFrom(string: privateKey) {
            if let _ = self.realm.object(ofType: OwnerKey.self, forPrimaryKey: keyPair.publicKey) {
                OwnerKey.saveKeyPairToKeychain(keyPair: keyPair)
            } else if let ownerKey = OwnerKey.create(withPrivateKey: privateKey) {
                try? realm.write {
                    self.realm.add(ownerKey, update: .all)
                }
            }
            if self.realm.object(ofType: PublicKeyMetaData.self, forPrimaryKey: keyPair.publicKey) == nil {
                try? realm.write {
                    self.realm.add(PublicKeyMetaData.create(withPublicKey: keyPair.publicKey))
                }
            }
            Task {
                await connectRelays()
            }
            return true
        }
        return false
    }
    
    @MainActor
    func updateRelayInformationForAll() async -> Void {
        let relays = self.realm.objects(Relay.self)
        await withTaskGroup(of: Void.self) { group in
            for relay in relays {
                group.addTask {
                    await relay.updateInfo()
                }
            }
        }
    }
    
    // TODO: Function to search for keys in keychain and restore accounts.
    
}
