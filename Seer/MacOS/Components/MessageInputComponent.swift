//
//  MessageInputComponent.swift
//  Seer
//
//  Created by Jacob Davis on 9/12/24.
//

import SwiftUI

struct MessageInputComponent: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var messageText = ""
    
    var body: some View {
        
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .imageScale(.large)
            
            TextField("Write something", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .onSubmit(of: .text, {
    //                if CGKeyCode.kVK_Shift.isPressed {
    //                    messageText += "\n"
    //                } else {
    //                    // Send
    //                }
                })
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundStyle(.secondary.opacity(0.3))
                )


            Image(systemName: "plus.circle.fill")
                .imageScale(.large)

        }
        .padding(.horizontal)
        .padding(.vertical)
        .background(
            .thinMaterial
        )
    }
}

#Preview {
    VStack {
        Text("hello")
        Text("hello")
        Text("hello")
        Spacer()
        MessageInputComponent()
    }
    .frame(width: 600, height: 400)
    
}
