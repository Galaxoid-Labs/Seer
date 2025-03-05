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
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: [String] = []
    
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
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .offset(x: 3, y: 1)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                if canCreate() {
                    Button("Create") {
                        guard let selectedOwnerAccount = appState.selectedOwnerAccount else {
                            return
                        }
                        self.isLoading = true
                        self.errorMessage.removeAll()
                        appState
                            .createGroup(
                                ownerAccount: selectedOwnerAccount,
                                groupId: groupId,
                                name: groupName
                                , about: groupAbout, picture: groupImageUrl) { error in
                            if let error = error {
                                print("Error creating group: \(error)")
                            }
                        }
                        //dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Create") {
                        
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }

            }
            
            if errorMessage.count > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(errorMessage, id: \.self) { m in
                        Label(m, systemImage: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .disabled(isLoading)
        .padding()
        .onChange(of: appState.eventSubmissions) { oldValue, newValue in
            if newValue.count == 2 && self.appState.eventSubmissions.map({ $0.isError == false }).count == 2 {
                dismiss()
                self.isLoading = false
                self.appState.eventSubmissions.removeAll()
                // TODO handle adding new group stuff
            } else if newValue.contains(where: { $0.isError }) {
                self.isLoading = false
                self.errorMessage = newValue.compactMap({ $0.errorMessage })
                self.appState.eventSubmissions.removeAll()
            }
        }
    }
    
    func canCreate() -> Bool {
        return groupId != "" && groupName != "" && !isLoading
    }
}

#Preview {
    MacOSCreateGroupView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppState.shared)
}
