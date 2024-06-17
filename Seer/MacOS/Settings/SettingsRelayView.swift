//
//  SettingsRelayView.swift
//  Seer
//
//  Created by Jacob Davis on 4/17/24.
//

import SwiftUI
import SwiftData
//import SwiftyPing

struct SettingsRelayView: View {
    
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var relays: [Relay]
    
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
                    //.disabled(!relayInputText.validRelayURL)
                }
                
            }
            
            Table(relays, selection: $selectedRelays) {
                TableColumn("URL", value: \.url)
                
                TableColumn("Name", value: \.name)
                TableColumn("Description", value: \.desc)
                TableColumn("Contact", value: \.contact)
                TableColumn("Nip29") { v in
                    if v.nip29Support() {
                        Image(systemName: "checkmark")
                    }
                }
                .width(40)
                TableColumn("Read") { v in
                    Toggle("", isOn: .constant(false))
                }
                .width(40)
                TableColumn("Write") { v in
                    Toggle("", isOn: .constant(false))
                }
                .width(40)
  

            }
            .alternatingRowBackgrounds()
            .tableStyle(.bordered)
        }
        .padding()
    }
    
    func addRelay() async {
        if let relay = Relay.createNew(withUrl: relayInputText) {
            modelContext.insert(relay)
            do {
                try modelContext.save()
            } catch {
                print(error)
            }
            _ = await relay.updateRelayInfo()
        }
    }
    
    func removeRelays() async {
        var selected: [Relay] = []
        for sr in selectedRelays {
            if let relay = self.relays.first(where: { $0.id == sr }) {
                selected.append(relay)
            }
        }
        
        let ids = selected.map { $0.url }
        appState.remove(relaysWithUrl: ids)
        
        for s in selected {
            modelContext.delete(s)
        }
        selectedRelays.removeAll()
    }
        
}

#Preview {
    SettingsRelayView()
        .environmentObject(AppState.shared)
}
