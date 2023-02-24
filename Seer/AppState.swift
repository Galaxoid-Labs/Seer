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
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?

    static let shared = AppState()
    
    let realm: Realm
    
    private init() {
        var config = Realm.Configuration(schemaVersion: 12)
        config.deleteRealmIfMigrationNeeded = true
        Realm.Configuration.defaultConfiguration = config
        self.realm = try! Realm()
        self.bootstrapRelays()
//        realm.writeAsync {
//            self.realm.deleteAll()
//        }
//        print(Keychain(service: "seer").allKeys())
        DispatchQueue.main.async {

            // Check eligible if not already verified at startup
            Task {
                await self.checkNip05UnVerified()
            }

            // Check eligible if not already verified
            self.checkUnverifiedTimer?.invalidate()
            self.checkUnverifiedTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] timer in
                Task {
                    await self?.checkNip05UnVerified()
                }
            }

            // Check the currently verified to see if something happend and they arent verified anymore
            self.checkVerifiedTimer?.invalidate()
            self.checkVerifiedTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] timer in
                Task {
                    await self?.checkNip05Verified()
                }
            }
        }
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
        print(self.relays.count)
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
                realm.writeAsync {
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
    
    @MainActor
    func checkNip05Verified() async -> Void {
        let publicKeyMetaDatas = self.realm.objects(PublicKeyMetaData.self).where({ $0.nip05Verified == true })
        await withTaskGroup(of: Void.self) { group in
            for publicKeyMetaData in publicKeyMetaDatas {
                group.addTask {
                    await publicKeyMetaData.updateNip05Verified()
                }
            }
        }
    }
    
    @MainActor
    func checkNip05UnVerified() async -> Void {
        let publicKeyMetaDatas = self.realm.objects(PublicKeyMetaData.self)
            .where({ $0.nip05Verified == false })
        await withTaskGroup(of: Void.self) { group in
            for publicKeyMetaData in publicKeyMetaDatas {
                if publicKeyMetaData.legitNipO5 {
                    group.addTask {
                        await publicKeyMetaData.updateNip05Verified()
                    }
                }
            }
        }
    }
    
    // TODO: Function to search for keys in keychain and restore accounts.
    
}
