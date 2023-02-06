//
//  Extensions.swift
//  Seer
//
//  Created by Jacob Davis on 2/5/23.
//

import Foundation

extension String {
    
    func isValidName() -> Bool {
        if self.isEmpty {
            return false
        }
        let nameRegex = #"^[\w+\-]*$"#
        return self.range(of: nameRegex, options: [.regularExpression]) != nil
    }
    
    func removingUrls() -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }
        return detector.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "")
    }
    
}

extension URL {
    public func isImageType() -> Bool {
        let imageFormats = ["jpg", "png", "gif"]
        let extensi = self.pathExtension
        return imageFormats.contains(extensi)
    }
    public func isVideoType() -> Bool {
        let videoFormats = ["mp4", "mov"]
        let extensi = self.pathExtension
        return videoFormats.contains(extensi)
    }
}
