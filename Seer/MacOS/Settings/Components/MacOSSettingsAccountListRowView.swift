//
//  SettingsAccountListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 4/18/24.
//

#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSSettingsAccountListRowView: View {
    
    var ownerKey: OwnerAccount
    @Binding var selectedOwnerAccount: OwnerAccount?
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "key.fill")
                .imageScale(.large)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .opacity(0.1)
                )
                .padding(.trailing, 4)
            LazyVStack(alignment: .leading) {
                Text(ownerKey.bestPublicName)
                    .lineLimit(1)
            }
            .truncationMode(.middle)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .listRowBackground(isSelected() ? Color.accentColor : Color.clear)
        .frame(height: 50)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .foregroundColor(isSelected() ? Color.white : Color(.labelColor))
        .background(isSelected() ? Color.accentColor : Color.clear)
        .onTapGesture {
            selectedOwnerAccount = ownerKey
        }
        
    }
    
    func isSelected() -> Bool {
        return ownerKey == selectedOwnerAccount
    }
}

//#Preview {
//    SettingsAccountListRowView()
//}
#endif
