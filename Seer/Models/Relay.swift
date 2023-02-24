//
//  Relay.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import Foundation
import RealmSwift

class Relay: Object, ObjectKeyIdentifiable {
    
    @Persisted(primaryKey: true) var url: String
    
    @Persisted var name: String
    @Persisted var desc: String
    @Persisted var publicKey: String
    @Persisted var contact: String
    @Persisted var supportedNips: MutableSet<Int>
    @Persisted var software: String
    @Persisted var version: String
    @Persisted var updatedAt: Date
    
    var httpUrl: URL? {
        let httpUrlString = url
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")
        return URL(string: httpUrlString)
    }
    
}

extension Relay {
    
    static func create(with urlString: String) -> Relay? {
        if urlString.validRelayURL {
            return Relay(value: ["url": urlString, "updatedAt": Date.distantPast])
        }
        return nil
    }
    
    static func bootstrap() -> [Relay] {
        return [
            Relay(value: ["url": "wss://nostr-relay.untethr.me", "updatedAt": Date.distantPast]),
            Relay(value: ["url": "wss://brb.io", "updatedAt": Date.distantPast]),
            Relay(value: ["url": "wss://relay.nostr.bg", "updatedAt": Date.distantPast]),
            Relay(value: ["url": "wss://eden.nostr.land", "updatedAt": Date.distantPast])
        ]
    }
    
    struct RelayInformation: Codable {
        var name: String?
        var description: String?
        var pubkey: String?
        var contact: String?
        var supported_nips: [Int]?
        var software: String?
        var version: String?
    }
    
    @MainActor
    func updateInfo() async {
        
        guard let httpUrl else {
            return
        }
        
        var urlRequest = URLRequest(url: httpUrl)
        urlRequest.setValue("application/nostr+json", forHTTPHeaderField: "Accept")
        
        if let res = try? await URLSession.shared.data(for: urlRequest) {
            DispatchQueue.main.async {
                let decoder = JSONDecoder()
                if let info = try? decoder.decode(RelayInformation.self, from: res.0) {
                    Task {
                        if let thawed = self.thaw() {
                            do {
                                try await Realm().writeAsync {
                                    thawed.name = info.name ?? self.name
                                    thawed.desc = info.description ?? self.desc
                                    thawed.publicKey = info.pubkey ?? self.publicKey
                                    thawed.version = info.version ?? self.version
                                    thawed.contact = info.contact ?? self.contact
                                    thawed.updatedAt = Date.now
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                } else {
                    print("Unable to decode relay information")
                }
            }
        }
    }
}

extension String {
    var validURL: Bool {
        get {
//            let regEx = "((?:http|https|ws|wss)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
//            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
//            return predicate.evaluate(with: self)
            return true
        }
    }
    var validRelayURL: Bool {
        get {
//            let regEx = "((?:ws|wss)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
//            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
//            return predicate.evaluate(with: self)
            return true
        }
    }
}
