//
//  MacOSCreateGroupView.swift
//  Seer
//
//  Created by Jacob Davis on 3/4/25.
//

import SwiftUI
import Nostr

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
    
    @State private var createGroupEvent: Event? = nil
    @State private var updateGroupEvent: Event? = nil

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
                        self.appState.eventSubmissions.removeAll()
                        
                        self.createGroupEvent = nil
                        self.updateGroupEvent = nil
                        
                        if let ce = appState.createGroup(ownerAccount: selectedOwnerAccount, groupId: groupId) {
                            self.createGroupEvent = ce
                        }
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
            
            if self.appState.eventSubmissions
                .contains(where: { $0.eventId == self.createGroupEvent?.id && $0.completed && $0.errorMessage == nil }) {
                if let selectedOwnerAccount = appState.selectedOwnerAccount {
                    self.appState.eventSubmissions.removeAll(where: { $0.eventId == self.createGroupEvent?.id })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if let ug = self.appState.editGroup(
                            ownerAccount: selectedOwnerAccount,
                            groupId: self.groupId,
                            name: self.groupName,
                            about: self.groupAbout,
                            picture: self.groupImageUrl
                        ) {
                            self.updateGroupEvent = ug
                        }
                    }
                }
            }
            
            // Finished Successfully
            if self.appState.eventSubmissions
                .contains(where: { $0.eventId == self.updateGroupEvent?.id && $0.completed && $0.errorMessage == nil }) {
                self.isLoading = false
                self.appState.eventSubmissions.removeAll()
                dismiss()
            }
            
            // Check for errors
            if self.appState.eventSubmissions.contains(where: { $0.errorMessage != nil && $0.completed }) {
                self.isLoading = false
                self.errorMessage.removeAll()
                self.errorMessage = self.appState.eventSubmissions.compactMap({ $0.errorMessage })
            }
            
        }
        .onDisappear {
            self.appState.eventSubmissions.removeAll() // TODO: Only remove events we know about...
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
