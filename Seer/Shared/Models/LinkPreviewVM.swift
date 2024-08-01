//
//  LinkPreviewVM.swift
//  Seer
//
//  Created by Jacob Davis on 7/3/24.
//

import Foundation
import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

final class LinkPreviewVM: ObservableObject {
    
#if os(macOS)
    @Published var image: NSImage?
    @Published var icon: NSImage?
#elseif os(iOS)
    @Published var image: UIImage?
    @Published var icon: UIImage?
#endif
    @Published var title: String?
    @Published var url: String?
    
    let previewURL: URL?
    
    init(_ url: String) {
        self.previewURL = URL(string: url)
        fetchMetadata()
    }
    
    private func fetchMetadata() {
        guard let previewURL else { return }
        let provider = LPMetadataProvider()
        
        Task {
            let metadata = try await provider.startFetchingMetadata(for: previewURL)
            
            image = try await convertToImage(metadata.imageProvider)
            icon = try await convertToImage(metadata.iconProvider)
            title = metadata.title
            
            url = metadata.url?.host()
        }
    }

#if os(macOS)
    private func convertToImage(_ imageProvider: NSItemProvider?) async throws -> NSImage? {
        
    var image: NSImage?

        if let imageProvider {
            let type = String(describing: UTType.image)
            
            if imageProvider.hasItemConformingToTypeIdentifier(type) {
                let item = try await imageProvider.loadItem(forTypeIdentifier: type)
                
                if item is NSImage {
                    image = item as? NSImage
                }
                
                if item is URL {
                    guard let url = item as? URL,
                          let data = try? Data(contentsOf: url) else { return nil }
                    
                    image = NSImage(data: data)
                }
                
                if item is Data {
                    guard let data = item as? Data else { return nil }
                    
                    image = NSImage(data: data)
                }
                
            }

        }
        
        return image
    }
    #elseif os(iOS)
    
    private func convertToImage(_ imageProvider: NSItemProvider?) async throws -> UIImage? {
        
    var image: UIImage?

        
        if let imageProvider {
            let type = String(describing: UTType.image)
            
            if imageProvider.hasItemConformingToTypeIdentifier(type) {
                let item = try await imageProvider.loadItem(forTypeIdentifier: type)
                
                if item is UIImage {
                    image = item as? UIImage
                }
                
                if item is URL {
                    guard let url = item as? URL,
                          let data = try? Data(contentsOf: url) else { return nil }
                    
                    image = UIImage(data: data)
                }
                
                if item is Data {
                    guard let data = item as? Data else { return nil }
                    
                    image = UIImage(data: data)
                }
                
            }

        }
        
        return image
    }
    #endif
}
