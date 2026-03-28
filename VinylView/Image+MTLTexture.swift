//
//  Image+MTLTexture.swift
//  VinylView
//
//  Created by Enie Weiß on 02.10.22.
//


#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit

extension UIImage {
    convenience init?(mtlTexture: MTLTexture) {
        guard let ciImage = CIImage(mtlTexture: mtlTexture)
        else {
            return nil
        }
        
        self.init(ciImage: ciImage)
    }
}

#elseif os(macOS)

import AppKit

extension NSImage {
    convenience init?(mtlTexture: MTLTexture) {
        guard let ciImage = CIImage(mtlTexture: mtlTexture)
        else {
            return nil
        }

        let rep = NSCIImageRep(ciImage: ciImage)
//        let nsImage = NSImage(size: rep.size)
//        nsImage.addRepresentation(rep)
        
        self.init(size: rep.size)
        self.addRepresentation(rep)
    }
}

#endif
