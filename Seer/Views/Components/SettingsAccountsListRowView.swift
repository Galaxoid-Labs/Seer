//
//  SettingsAccountsListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 2/20/23.
//

import SwiftUI
import RealmSwift

struct SettingsAccountsListRowView: View {
    
    @ObservedRealmObject var ownerKey: OwnerKey
    @Binding var selectedOwnerKey: OwnerKey?
    
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
            selectedOwnerKey = ownerKey
        }
        
    }
    
    func isSelected() -> Bool {
        return ownerKey == selectedOwnerKey
    }
}

struct SettingsAccountsListRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SettingsAccountsListRowView(ownerKey: OwnerKey.preview, selectedOwnerKey: .constant(OwnerKey.preview))
            SettingsAccountsListRowView(ownerKey: OwnerKey.preview2, selectedOwnerKey: .constant(OwnerKey.preview))
        }
        .listStyle(.bordered)
        .frame(width: 250)

    }
}
