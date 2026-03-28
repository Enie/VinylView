//
//  AnimatedImageView.swift
//  VinylView
//
//  Created by Enie Weiß on 12.04.23.
//

import Foundation

import MetalKit

public final class AnimatedImageView: MTKView {
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var textureArray: ImageTextureArray!
    private var index: Int = 0
    private var isPlaying: Bool = false
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, device: MTLDevice, images: [CGImage]) {
        super.init(frame: frame, device: device)
        self.translatesAutoresizingMaskIntoConstraints = true
        self.colorPixelFormat = .bgra8Unorm
        self.delegate = self
        self.preferredFramesPerSecond = 30
        self.framebufferOnly = false
        
        setUpMetal()
        setUpBuffers()
        try! setUpTextureArray(with: images)
    }

    func setUpMetal() {
        let frameworkBundle = Bundle.vinylView
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        guard let device = self.device,
              let commandQueue = device.makeCommandQueue(),
              let library = try? device.makeDefaultLibrary(bundle: frameworkBundle),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main")
        else {
            fatalError("GPU pipeline failed")
        }
        
        self.commandQueue = commandQueue
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state: \(error)")
        }
    }
    
    func setUpBuffers() {
        let vertices: [Float] = [
            -1, -1, 0, 1,
             1, -1, 1, 1,
             -1,  1, 0, 0,
             1,  1, 1, 0
        ]
        vertexBuffer = device!.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
        
        let indices: [UInt16] = [
            0, 1, 2,
            1, 3, 2
        ]
        indexBuffer = device!.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
    }
    
    func setUpTextureArray(with images: [CGImage]) throws {
        textureArray = try ImageTextureArray(device: device!, images: images)
    }
    
    func startAnimating() {
        isPlaying = true
    }

    func stopAnimating() {
        isPlaying = false
    }
}

extension AnimatedImageView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        autoreleasepool {
            guard view.frame.width > 0 && view.frame.height > 0,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            var frame = index/3
            renderEncoder.setFragmentBytes(&frame, length: MemoryLayout<Int>.size, index: 0)
            renderEncoder.setFragmentTexture(textureArray.textureArray, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.size, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
            if isPlaying {
                index = Int(index + 1) % (textureArray.count*3)
            } else {
                view.isPaused = true
            }
        }
    }
}
