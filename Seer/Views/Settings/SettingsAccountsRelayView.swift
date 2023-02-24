//
//  SettingsAccountsRelayView.swift
//  Seer
//
//  Created by Jacob Davis on 2/20/23.
//

import SwiftUI
import RealmSwift

struct SettingsAccountsRelayView: View {
    
    struct RelayToggleModel: Identifiable, Equatable {
        var id: String
        var url: String
        var metaDataIsOn: Bool
        var messagesIsOn: Bool
    }
    
    @EnvironmentObject private var appState: AppState
    
    @Binding var ownerKey: OwnerKey?
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedResults(Relay.self) var globalRelays
    
    @State var relayModels = [RelayToggleModel]()

    var body: some View {
        VStack {
            
            Table(relayModels) {
                TableColumn("URL", value: \.url)
                TableColumn("Metadata (Read/Write)") { relayModel in
                    Toggle("Enabled", isOn: Binding<Bool>(
                        get: {
                            return relayModel.metaDataIsOn
                        },
                        set: {
                           if let index = relayModels.firstIndex(where: { $0.id == relayModel.id }) {
                               relayModels[index].metaDataIsOn = $0
                               print(relayModels[index].metaDataIsOn)
                               if let realm = try? Realm(), let ownerKey {
                                   realm.writeAsync {
                                       if let o = realm.object(ofType: OwnerKey.self, forPrimaryKey: ownerKey.publicKey) {
                                           if relayModels[index].metaDataIsOn {
                                               o.metaDataRelayIds.insert(relayModel.url)
                                               print("ADDED")
                                           } else {
                                               o.metaDataRelayIds.remove(relayModel.url)
                                               print("REMOVED")
                                           }
                                       }

                                   }
                               }
                           }
                        }
                     ))
                    .toggleStyle(.checkbox)
                }
                TableColumn("Messages (Read/Write)") { relayModel in
                    Toggle("Enabled", isOn: Binding<Bool>(
                        get: {
                            return relayModel.messagesIsOn
                        },
                        set: {
                           if let index = relayModels.firstIndex(where: { $0.id == relayModel.id }) {
                               relayModels[index].messagesIsOn = $0
                               if let realm = try? Realm(), let ownerKey {
                                   realm.writeAsync {
                                       let o = realm.object(ofType: OwnerKey.self, forPrimaryKey: ownerKey.publicKey)
                                       if relayModels[index].messagesIsOn {
                                           o?.messageRelayIds.insert(relayModel.url)
                                       } else {
                                           o?.messageRelayIds.remove(relayModel.url)
                                       }
                                   }
                               }
                           }
                        }
                     ))
                    .toggleStyle(.checkbox)
                }
            }
            .tableStyle(.bordered)
            .onChange(of: relayModels) { newValue in
                print("Changed here...")
            }
        }
        .onAppear {
            if let ownerKey {
                self.relayModels.removeAll()
                let relays = Array(globalRelays)
                let accountMetaDataRelayIds = Array(ownerKey.metaDataRelayIds)
                let accountMessageRelayIds = Array(ownerKey.messageRelayIds)
                
                for relay in relays {
                    var model = RelayToggleModel(id: relay.url, url: relay.url, metaDataIsOn: false, messagesIsOn: false)
                    if accountMetaDataRelayIds.contains(relay.url) {
                        model.metaDataIsOn = true
                    }
                    if accountMessageRelayIds.contains(relay.url) {
                        model.messagesIsOn = true
                    }
                    relayModels.append(model)
                }
            }
        }
    }
}

struct SettingsAccountsRelayView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAccountsRelayView(ownerKey: .constant(OwnerKey.preview))
            .environmentObject(AppState.shared)
    }
}
