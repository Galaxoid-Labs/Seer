//
//  MacOSStartAddMetadataRelay.swift
//  Seer
//
//  Created by Jacob Davis on 7/24/24.
//

import SwiftUI
import SwiftData

struct MacOSStartAddMetadataRelay: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    @Binding var navigationPath: NavigationPath
    
    @Query private var relays: [Relay]
    var metadataRelays: [Relay] {
        return relays.filter({ $0.supportsNip1 })
    }
    
    @State var suggestedRelays: [String] = ["wss://purplepag.es"]
    var filteredSuggestedRelays: [String] {
        return suggestedRelays.filter { s in !metadataRelays.contains { r in r.url == s }}
    }
    
    var body: some View {
        ZStack {
           
            VStack(spacing: 16) {
                
                Image(systemName: "network")
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
                    .imageScale(.large)
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .background(LinearGradient(colors: [.purple, .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(spacing: 8) {
                    Text("Add Metadata Relay")
                        .font(.title)
                        .bold()
                    Text("Adding a metadata relay allows you to retrieve and store extra info")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                
                Divider()
               
                HStack {
                    TextField("wss://<metadata relay>", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        Task {
                            await addRelay(relayUrl: inputText)
                        }
                    }
                }
                
                List {
                    Section("Connected Metadata Relays") {
                        ForEach(relays) { relay in
                            HStack {
                                Text(relay.url)

                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        await removeRelay(relay: relay)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .imageScale(.large)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Section("Suggested Metadata Relays") {
                        ForEach(filteredSuggestedRelays, id: \.self) { relay in
                            HStack {
                                Text(relay)

                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        await addRelay(relayUrl: relay)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .imageScale(.large)
                                        .foregroundStyle(.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .listStyle(.bordered)
                
            }
            .padding(.top, 32)
            .padding(.bottom, 6)
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            
            HStack {
                Spacer()
                Button("Back") {
                    self.navigationPath.removeLast()
                }
                if !nextEnabled() {
                    NavigationLink("Next", value: 2)
                        .buttonStyle(.bordered)
                        .disabled(!nextEnabled())
                } else {
                    NavigationLink("Next", value: 2)
                        .buttonStyle(.borderedProminent)
                        .disabled(!nextEnabled())
                }
                    
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
            
        }
    }
    
    
    func addRelay(relayUrl: String) async {
        if relays.contains(where: { $0.url == relayUrl }) {
            inputText = ""
            return
        }
        
        if let relay = Relay.createNew(withUrl: relayUrl) {
            modelContext.insert(relay)
            do {
                try modelContext.save()
            } catch {
                print(error)
            }
            _ = await relay.updateRelayInfo()
            
            if !relay.supportsNip1 {
                print("Nip 29 support")
                modelContext.delete(relay)
            } else {
                inputText = ""
            }
        }
    }
    
    func removeRelay(relay: Relay) async {
        appState.remove(relaysWithUrl: [relay.url])
        modelContext.delete(relay)
        await appState.removeDataFor(relayUrl: relay.url)
    }
    
    func nextEnabled() -> Bool {
        return metadataRelays.count > 0
    }
}

#Preview {
    NavigationStack {
        MacOSStartAddMetadataRelay(navigationPath: .constant(NavigationPath()))
            .environmentObject(AppState.shared)
    }
    .frame(width: 400, height: 500)
}
