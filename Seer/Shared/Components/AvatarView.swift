//
//  AvatarView.swift
//  Seer
//
//  Created by Jacob Davis on 4/18/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    
    let avatarUrl: String
    let size: CGFloat
    
    var body: some View {
        AnimatedImage(url: URL(string: avatarUrl), placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: size))
        })
        .resizable()
        .frame(width: size, height: size)
        .aspectRatio(contentMode: .fill)
        .background(.gray)
        .cornerRadius(size/2)
    }
}


#Preview {
    AvatarView(avatarUrl: "https://fiatjaf.com/static/favicon.jpg", size: 40)
        .frame(width: 100, height: 50)
}
