//
//  SettingsRelayView.swift
//  Seer
//
//  Created by Jacob Davis on 2/3/23.
//

import SwiftUI
import RealmSwift
import SwiftyPing

struct SettingsRelayView: View {
    
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedResults(Relay.self) var relays
    
    @State private var selectedRelays = Set<Relay.ID>()
    @State private var durations: [String: Int] = [:]
    @State private var relayInputText = ""

    var body: some View {
        VStack {

            HStack {

                if selectedRelays.count > 0 {
                    Spacer()
                    Button(role: .destructive, action: {
                        Task {
                            await removeRelays()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: {
                        Task {
                            await checkPings()
                        }
                    }) {
                        Image(systemName: "repeat")
                    }
                    
                    Spacer()
                    
                    TextField("wss://...", text: $relayInputText)
                        .frame(width: 200)
                        .textFieldStyle(.roundedBorder)
                    Button(action: {
                        Task {
                            await addRelay()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!relayInputText.validRelayURL)
                }
                
            }
            
            Table(relays, selection: $selectedRelays) {
                TableColumn("URL", value: \.url)
                TableColumn("Contact", value: \.contact)
                TableColumn("Latency") { r in
                    if let duration = self.durations[r.url] {
                        HStack {
                            Text("\(duration)ms")
                            Image(systemName: "circle.fill")
                                .foregroundColor(duration < 100 ? .green : .yellow)
                        }
                    } else {
                        HStack {
                            Text("?")
                            Image(systemName: "circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .tableStyle(.bordered)

        }
        .padding()
        .task {
            await checkPings()
        }
    }
        
    @MainActor
    func checkPings() async {
        for relay in relays {
            if let url = relay.httpUrl?.host() {
                let once = try? SwiftyPing(host: url,
                                           configuration: PingConfiguration(interval: 0.5, with: 5),
                                           queue: DispatchQueue.global())
                once?.observer = { (response) in
                    self.durations[relay.url] = Int(response.duration * 1_000)
                }
                once?.targetCount = 3
                try? once?.startPinging()
            }
        }
    }
    
    @MainActor
    func addRelay() async {
        if let relay = Relay.create(with: relayInputText) {
            if let realm = try? await Realm() {
                try? realm.write {
                    realm.add(relay, update: .all)
                }
                Task {
                    await appState.updateRelayInformationForAll()
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    Task {
                        await checkPings()
                    }
                }
                self.relayInputText = ""
            }
        }
    }
    
    @MainActor
    func removeRelays() async {
        var selected: [Relay] = []
        for sr in selectedRelays {
            if let relay = relays.first(where: {
                $0.id == sr
            }) {
                selected.append(relay)
            }
        }
        
        let ids = selected.map { $0.url }
        
        if ids.count > 0 {
            if let realm = try? await Realm() {
                let remove = realm.objects(Relay.self).where {
                    $0.url.in(ids)
                }
                try? realm.write {
                    realm.delete(remove)
                }
            }
            self.selectedRelays.removeAll()
        }
    }
}

struct SettingsRelayView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRelayView()
            .environmentObject(AppState.shared)
    }
}
