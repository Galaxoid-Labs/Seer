//
//  MacOSGroupListRowView.swift
//  Seer
//
//  Created by Jacob Davis on 6/12/24.
//
#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSGroupListRowView: View {
    
    let group: Group
    let lastMessage: ChatMessage?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(group.name ?? "")
                    .bold()
                Spacer()
                if let lastMessage {
                    Text(lastMessage.createdAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(group.id)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(lastMessage?.content ?? "")
                .lineLimit(2)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 60)
    }
}

//#Preview {
//    let container = PreviewData.container
//    let simpleGroupA = SimpleGroup(id: "016fb665", relayUrl: "wss://groups.fiatjaf.com", name: "General", isPublic: true, isOpen: true)
//    @State var selectedGroup = simpleGroupA
//    
//    return VStack {
//        List(selection: $selectedGroup) {
//            NavigationLink(value: simpleGroupA) {
//                MacOSGroupListRowView(group: simpleGroupA, lastMessage: "Hey, that was cool!", lastMessageDate: .now)
//            }
//        }
//        .listStyle(.plain)
//        .frame(minWidth: 300)
//    }
//}
#endif
