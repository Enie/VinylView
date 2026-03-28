//
//  NSAnimationImage.swift
//  VinylView
//
//  Created by Enie Weiß on 11.04.23.
//

import SwiftUI

public struct AnimatedImage: NSUIViewRepresentable {
    public let animationImage: NSUIImage
    public let isAnimating: Bool

#if os(iOS) || os(watchOS) || os(tvOS)
    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = animationImage
        
        return imageView
    }
    
    public func updateUIView(_ uiView: UIImageView, context: Context) {
        if isAnimating {
            uiView.stopAnimating()
        } else {
            uiView.startAnimating()
            
        }
    }
    
    typealias UIViewType = UIImageView
#elseif os(macOS)
    public func makeNSView(context: Context) -> NSImageView {
        let nsImageView = NSImageView()
        nsImageView.wantsLayer = true
        nsImageView.canDrawSubviewsIntoLayer = true
        nsImageView.imageScaling = .scaleProportionallyUpOrDown
        nsImageView.animates = false
        
        nsImageView.image = animationImage
        
        return nsImageView
    }
    
    public func updateNSView(_ nsView: NSImageView, context: Context) {
        if isAnimating {
            nsView.animates = true
        } else {
            nsView.animates = false
        }
    }
#endif
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator {
        public var parent: AnimatedImage
        
        init(_ parent: AnimatedImage) {
            self.parent = parent
        }
    }
}

struct NSAnimatedImage_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedImage(animationImage: VinylGenerator.recordAnimation(diameter: 300, duration: 2)!, isAnimating: true)
    }
}
