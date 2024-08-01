//
//  LinkPreviewView.swift
//  Seer
//
//  Created by Jacob Davis on 7/3/24.
//

#if os(macOS)
import SwiftUI

struct LinkPreviewView: View {
    
    let owner: Bool
    @ObservedObject var viewModel: LinkPreviewVM

    var body: some View {
        
        if let image = viewModel.image {
            VStack {
                Image(nsImage: image)
                    .resizable()
                    //.aspectRatio(1.33, contentMode: .fill)
                    //.frame(maxWidth: 266, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack {
                    VStack(alignment: .leading, spacing: 1, content: {
                        if let title = viewModel.title {
                            Text(title)
                                .font(.body)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .bold()
                        }
                        
                        if let url = viewModel.url {
                            Text(url)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                        }
                    })
                    Spacer()
                }

            }
            //.frame(maxWidth: .infinity, maxHeight: 100)
            .aspectRatio(1.33, contentMode: .fill)
            .frame(maxWidth: 266, maxHeight: 200)
            .padding(8)
            .background(owner ? .accent : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))

        } else if let icon = viewModel.icon {
            HStack {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 1, content: {
                    if let title = viewModel.title {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .bold()
                    }
                    
                    if let url = viewModel.url {
                        Text(url)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                    }
                })
            }
//            .aspectRatio(1.33, contentMode: .fill)
//            .frame(maxWidth: 266, maxHeight: 200)
            .padding(8)
            .background(owner ? .accent : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            HStack {
                ProgressView()
            }
            //.aspectRatio(1.33, contentMode: .fill)
            //.frame(maxWidth: 266, maxHeight: 200)
            .padding(8)
            .background(owner ? .accent : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        
        


    }
}

#Preview {
    VStack {
        LinkPreviewView(owner: true, viewModel: .init("https://www.autosport.com"))
        LinkPreviewView(owner: false, viewModel: .init("https://galaxoidlabs.com"))
        LinkPreviewView(owner: true, viewModel: .init("https://opensats.org/blog/bitcoin-grants-july-2024"))
    }
    .frame(width: 400, height: 800)
    .background(.accent)
}
#endif
