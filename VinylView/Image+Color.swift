#if canImport(AppKit)
import CoreGraphics
import AppKit

public extension NSImage {

    static func imageWith(color: NSColor, size: CGSize = CGSize(width: 1, height: 1)) -> NSImage {
//        guard let offscreenRep: NSBitmapImageRep = NSBitmapImageRep(bitmapDataPlanes: nil,
//                                                              pixelsWide: Int(size.width),
//                                                              pixelsHigh: Int(size.height),
//                                                              bitsPerSample: 8,
//                                                              samplesPerPixel: 4,
//                                                              hasAlpha: true,
//                                                              isPlanar: false,
//                                                              colorSpaceName: .deviceRGB,
//                                                              bytesPerRow: 0,
//                                                              bitsPerPixel: 0),
//              let context = NSGraphicsContext(bitmapImageRep: offscreenRep)
//        else {
//            return NSImage(size: NSSize(width: size.width, height: size.height))
//        }
        let image = NSImage(size: size)
        image.lockFocus()
//        let cgContext = context.cgContext
        
        color.setFill()
        CGRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        
//        let image = NSImage(size: size)
//        image.addRepresentation(offscreenRep)
        return image
    }

    static func blank(size: CGSize = CGSize(width: 1, height: 1)) -> NSImage {
        self.imageWith(color: .clear, size: size)
    }
    
    /// Generates a blank (transparent) 1 × 1 image
    static var blank: NSImage { .blank() }
}

#else

import UIKit

extension UIImage {
    class func imageWith(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

#endif
