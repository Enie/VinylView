//
//  AnimatedMetalImage.swift
//  VinylView
//
//  Created by Enie Weiß on 12.04.23.
//

import SwiftUI

public struct AnimatedMetalImage: NSUIViewRepresentable {
    public let images: [CGImage]
    public let isPlaying: Bool
    
    public init(images: [CGImage], isPlaying: Bool) {
        self.images = images
        self.isPlaying = isPlaying
    }
    
#if os(iOS) || os(watchOS) || os(tvOS)
    public func makeUIView(context: Context) -> AnimatedImageView {
        let device = MTLCreateSystemDefaultDevice()!
        let animatedImageView = AnimatedImageView(frame: .zero, device: device, images: images)
        return animatedImageView
    }
    
    public func updateUIView(_ uiView: AnimatedImageView, context: Context) {
        isPlaying ? nsView.startAnimating() : nsView.stopAnimating()
    }
#elseif os(macOS)
    public func makeNSView(context: Context) -> AnimatedImageView {
        let device = MTLCreateSystemDefaultDevice()!
        let width = images[0].width
        let height = images[0].height
        let animatedImageView = AnimatedImageView(frame: NSRect(x: 0, y: 0, width:width , height: height), device: device, images: images)
//        animatedImageView.boundsRotation = 45
        return animatedImageView
    }
    
    public func updateNSView(_ nsView: AnimatedImageView, context: Context) {
        if isPlaying {
            nsView.isPaused = false
            nsView.startAnimating()
        } else {
//            let it draw first frame and the draw function will set the view to be paused
            nsView.stopAnimating()
        }
    }
#endif
}

struct AnimatedMetalImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AnimatedMetalImage(images: VinylGenerator.recordFrames(diameter: 300, duration: 2), isPlaying: true)
                .frame(width: 300, height: 300)
        }
    }
}
