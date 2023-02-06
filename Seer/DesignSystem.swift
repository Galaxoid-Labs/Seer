//
//  Extensions.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import Foundation
import SwiftUI

struct TileBackground: View {
    var body: some View {
        Image("tile_pattern_2")
            .resizable(resizingMode: .tile)
            .colorMultiply(Color("Secondary"))
            .opacity(0.1)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                LinearGradient(gradient: Gradient(colors: [.clear, Color("Secondary").opacity(0.1)]), startPoint: .top, endPoint: .bottom)
            )
    }
}
