//
//  MacOSCreateGroupView.swift
//  Seer
//
//  Created by Jacob Davis on 3/4/25.
//

import SwiftUI

struct MacOSCreateGroupView: View {
    
    @EnvironmentObject var appState: AppState
    
    @State private var groupId: String = ""
    @State private var groupName: String = ""
    @State private var groupImageUrl: String = ""
    @State private var groupAbout: String = ""
    @State private var groupOpen: Bool = true
    @State private var groupPublic: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Group")
                .font(.headline)
            
            Form {
                TextField("ID", text: $groupId)
                TextField("Name", text: $groupName)
                TextField("Description", text: $groupAbout, axis: .vertical)
                TextField("Image Url", text: $groupImageUrl)
            }
            .textFieldStyle(.roundedBorder)
            //.formStyle(.grouped)
            
            HStack {
                Spacer()
                Toggle("Open", isOn: $groupOpen)
                    .toggleStyle(.switch)
                    .disabled(true)
                Toggle("Public", isOn: $groupPublic)
                    .toggleStyle(.switch)
                    .disabled(true)
            }
            .padding(.bottom, 16)

            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                if canCreate() {
                    Button("Create") {
                        guard let selectedOwnerAccount = appState.selectedOwnerAccount else {
                            return
                        }
                        
                        appState.createGroup(ownerAccount: selectedOwnerAccount, groupId: groupId) { error in
                            if let error = error {
                                print("Error creating group: \(error)")
                            }
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Create") {
                        
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }

            }
        }
        .padding()
    }
    
    func canCreate() -> Bool {
        return groupId != "" && groupName != ""
    }
}

#Preview {
    MacOSCreateGroupView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
