//
//  MetalView.swift
//  VinylView
//
//  Created by Enie Weiß on 13.04.23.
//

import SwiftUI
import MetalKit

let maxBuffersInFlight = 3

struct MetalView: NSViewRepresentable {
    @StateObject var renderer: VinylGenerator
    var isPlaying: Bool = false
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: renderer.device)
        
        mtkView.preferredFramesPerSecond = 24
        mtkView.framebufferOnly = false
//        mtkView.boundsRotation = -45

        return mtkView
    }
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
        renderer.isPaused = !isPlaying
        if isPlaying {
            nsView.isPaused = false
        }
        if nsView.delegate == nil {
            nsView.delegate = renderer
        }
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MetalView(renderer: VinylGenerator(), isPlaying: true)
            .frame(width: 400, height: 400)
    }
}
