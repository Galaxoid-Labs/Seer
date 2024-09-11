//
//  URL.swift
//  Seer
//
//  Created by Jacob Davis on 7/3/24.
//

public import Foundation

extension URL {
    public func isImageType() -> Bool {
        let imageFormats = ["jpg", "png", "gif", "webp", "jpeg", "svg"]
        let extensi = self.pathExtension.lowercased()
        return imageFormats.contains(extensi)
    }
    public func isVideoType() -> Bool {
        let videoFormats = ["mp4", "mov"]
        let extensi = self.pathExtension.lowercased()
        return videoFormats.contains(extensi)
    }
}
