//
//  RelayToggleView.swift
//  Seer
//
//  Created by Jacob Davis on 2/3/23.
//

import SwiftUI
import RealmSwift

struct RelayToggleView: View {
    
    @ObservedResults(Relay.self) var relays
    
    @State private var selectedRelays = Set<Relay.ID>()
    
    var body: some View {
        VStack {
            
            Text("Select 1 or more relays")
            
            Table(relays, selection: $selectedRelays) {
                TableColumn("URL", value: \.url)
                TableColumn("Contact", value: \.contact)
                TableColumn("Updated") { r in
                    Text(r.updatedAt, style: .date)
                }
            }
            .cornerRadius(8)
            .shadow(radius: 1)
            
            HStack {
                Spacer()
                Button("Save") {
                    
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 300)
    }
}

struct RelayToggleView_Previews: PreviewProvider {
    static var previews: some View {
        RelayToggleView()
    }
}
