#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

import UniformTypeIdentifiers
import MetalKit

public final class VinylGenerator: NSObject, MTKViewDelegate, ObservableObject {
    public let device: MTLDevice
    public var diameter: CGFloat?
    public var isPaused = true
    
    private var frameIndex: Int = 0
    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    let commandQueue: MTLCommandQueue

    private var generateNoisePipelineState: MTLComputePipelineState?
    private var fitPipelineState: MTLComputePipelineState?
    private var noiseTexture: MTLTexture?
    private var noiseTextureSize: Int = 0

    override init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        if let library = try? device.makeDefaultLibrary(bundle: Bundle(for: VinylGenerator.self)),
           let noiseFunc = library.makeFunction(name: "generateNoise"),
           let fitFunc = library.makeFunction(name: "fit") {
            generateNoisePipelineState = try? device.makeComputePipelineState(function: noiseFunc)
            fitPipelineState = try? device.makeComputePipelineState(function: fitFunc)
        }
    }

    private func makeNoiseTexture(size: Int) -> MTLTexture? {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: size, height: size, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = .private
        return device.makeTexture(descriptor: desc)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        autoreleasepool {
            _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

            guard let buffer = commandQueue.makeCommandBuffer() else {
                inFlightSemaphore.signal()
                return
            }
            let semaphore = inFlightSemaphore
            buffer.addCompletedHandler { _ in semaphore.signal() }

            guard let drawable = view.currentDrawable else { return }

            let noiseWidth = Int(diameter ?? CGFloat(drawable.texture.width))

            if noiseTexture == nil || noiseTextureSize != noiseWidth {
                noiseTexture = makeNoiseTexture(size: noiseWidth)
                noiseTextureSize = noiseWidth
            }

            guard let noiseTexture,
                  let generateNoisePipelineState,
                  let fitPipelineState else { return }

            // Pass 1: generate noise → intermediate texture
            if let enc = buffer.makeComputeCommandEncoder() {
                var timeOffset = Float(frameIndex)
                let (tw, th) = (32, 32)
                enc.setComputePipelineState(generateNoisePipelineState)
                enc.setTexture(noiseTexture, index: 0)
                enc.setBytes(&timeOffset, length: MemoryLayout<Float>.size, index: 0)
                enc.dispatchThreadgroups(
                    MTLSizeMake((noiseWidth + tw - 1) / tw, (noiseWidth + th - 1) / th, 1),
                    threadsPerThreadgroup: MTLSizeMake(tw, th, 1))
                enc.endEncoding()
            }

            // Pass 2: fit intermediate texture → drawable
            if let enc = buffer.makeComputeCommandEncoder() {
                let outW = drawable.texture.width
                let outH = drawable.texture.height
                let (tw, th) = (32, 32)
                enc.setComputePipelineState(fitPipelineState)
                enc.setTexture(noiseTexture, index: 0)
                enc.setTexture(drawable.texture, index: 1)
                enc.dispatchThreadgroups(
                    MTLSizeMake((outW + tw - 1) / tw, (outH + th - 1) / th, 1),
                    threadsPerThreadgroup: MTLSizeMake(tw, th, 1))
                enc.endEncoding()
            }

            buffer.present(drawable)
            buffer.commit()

            if !isPaused {
                frameIndex += 1
            } else {
                view.isPaused = true
            }
        }
    }
    
    static func textureWithNoise(diameter: Int, seed: Int = 0) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = diameter
        descriptor.height = diameter
        descriptor.usage = MTLTextureUsage([.shaderRead, .shaderWrite, .renderTarget, .pixelFormatView])
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: Bundle(for: self)),
              let function = library.makeFunction(name: "generateNoise"),
              let state = try? device.makeComputePipelineState(function: function),
              let texture = device.makeTexture(descriptor: descriptor),
              let commandQueue = device.makeCommandQueue(),
              let buffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = buffer.makeComputeCommandEncoder()
        else {
            print("damn")
            return nil
        }
        
        let height = texture.height
        let width = texture.width
        
        let threadGroupWidth = 32
        let threadGroupHeight = 32
        
        let threadsPerGroup = MTLSizeMake(threadGroupWidth, threadGroupHeight, 1)
        let numThreadgroups = MTLSizeMake(width/threadsPerGroup.width + 1, height/threadsPerGroup.height + 1, 1)
        
        var timeOffset = Float(seed)
        
        computeEncoder.setComputePipelineState(state)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBytes(&timeOffset, length: MemoryLayout<Float>.size, index: 0)
        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        buffer.commit()
        buffer.waitUntilCompleted()
        
        return texture
    }
    
    static func textureWithNoiseLine(diameter: Int, seed: Int = 0) -> MTLTexture? {
        autoreleasepool {
            let descriptor = MTLTextureDescriptor()
            descriptor.width = diameter
            descriptor.height = diameter
            descriptor.usage = MTLTextureUsage([.shaderRead, .shaderWrite, .renderTarget, .pixelFormatView])
            
            guard let device = MTLCreateSystemDefaultDevice(),
                  let library = try? device.makeDefaultLibrary(bundle: Bundle(for: self)),
                  let function = library.makeFunction(name: "generateNoiseLine"),
                  let state = try? device.makeComputePipelineState(function: function),
                  let texture = device.makeTexture(descriptor: descriptor),
                  let commandQueue = device.makeCommandQueue(),
                  let buffer = commandQueue.makeCommandBuffer(),
                  let computeEncoder = buffer.makeComputeCommandEncoder()
            else {
                print("damn")
                return nil
            }
            
            let height = texture.height
            let width = texture.width
            
            let threadGroupWidth = 32
            let threadGroupHeight = 32
            
            let threadsPerGroup = MTLSizeMake(threadGroupWidth, threadGroupHeight, 1)
            let numThreadgroups = MTLSizeMake(width/threadsPerGroup.width + 1, height/threadsPerGroup.height + 1, 1)
            
            var timeOffset = Float(seed)
            
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setTexture(texture, index: 0)
            computeEncoder.setBytes(&timeOffset, length: MemoryLayout<Float>.size, index: 0)
            computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()
            buffer.commit()
            buffer.waitUntilCompleted()
            
            return texture
        }
    }
    
#if os(iOS) || os(watchOS) || os(tvOS)
    public static func recordImage(diameter: CGFloat, frame: Int = 0) -> UIImage {
        guard let noise = self.textureWithNoise(diameter: Int(diameter), seed: frame),
              let image = UIImage(mtlTexture: noise)
//              let blurredTexture = MTLFilter.radialBlur(texture: noise),
//              let image = UIImage(mtlTexture: blurredTexture)
        else {
            return UIImage.imageWith(color:.green, size:CGSize(width: diameter, height: diameter))
        }
        return image
    }
#elseif os(macOS)
    public static func recordImage(diameter: CGFloat, frame: Int = 0) -> NSImage {
        guard let noise = self.textureWithNoise(diameter: Int(diameter), seed: frame),
              let image = NSImage(mtlTexture: noise)
//              let blurredTexture = MTLFilter.radialBlur(texture: noise),
//              let image = NSImage(mtlTexture: blurredTexture)
        else {
            return NSImage.imageWith(color:.green, size:CGSize(width: diameter, height: diameter))
        }

        return image
    }
#endif

#if os(iOS) || os(watchOS) || os(tvOS)
    public static func recordAnimation(diameter: CGFloat, duration: Double) -> UIImage? {
        let totalFrames = 20

        //create empty file to hold gif
        let destinationFilename = String(NSUUID().uuidString + ".gif")
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(destinationFilename)
        //metadata for gif file to describe it as an animated gif
        let fileDictionary = [kCGImagePropertyGIFDictionary : [
            kCGImagePropertyGIFLoopCount : 0]]
        //create the file and set the file properties
        
        guard let animatedGifFile = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.gif.identifier as CFString, totalFrames, nil) else {
            print("error creating gif file")
            return nil
        }
        CGImageDestinationSetProperties(animatedGifFile, fileDictionary as CFDictionary)
        
        let frameDictionary = [kCGImagePropertyGIFDictionary : [
            kCGImagePropertyGIFDelayTime: 1.0 / 10.0]]
        
        for i in 0..<totalFrames {
            let frameImage = VinylGenerator.recordImage(diameter: diameter, frame: i).cgImage
            if let frame = frameImage {
                CGImageDestinationAddImage(animatedGifFile, frame, frameDictionary as CFDictionary)
            }
        }
        
        CGImageDestinationFinalize(animatedGifFile)
        
        if let data = try? Data(contentsOf: destinationURL) {
            let animatedImage = NSUIImage(data: data)
            return animatedImage
        }
        return nil
    }
    
#elseif os(macOS)
    public static func recordAnimation(diameter: CGFloat, duration: Double) -> NSImage? {
        let totalFrames = 20
        
        //create empty file to hold gif
        let destinationFilename = String(NSUUID().uuidString + ".gif")
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(destinationFilename)
        
        //metadata for gif file to describe it as an animated gif
        let fileDictionary = [kCGImagePropertyGIFDictionary : [
            kCGImagePropertyGIFLoopCount : 0]]
        
        //create the file and set the file properties
        guard let animatedGifFile = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.gif.identifier as CFString, totalFrames, nil) else {
            print("error creating gif file")
            return nil
        }
    
        CGImageDestinationSetProperties(animatedGifFile, fileDictionary as CFDictionary)
        
        let frameDictionary = [kCGImagePropertyGIFDictionary : [
            kCGImagePropertyGIFDelayTime: 1.0 / 10.0]]
        
        for i in 0..<totalFrames {
            let frameImage = VinylGenerator.recordImage(diameter: diameter, frame: i).cgImage(forProposedRect: nil, context: nil, hints: nil)
            if let frame = frameImage {
                CGImageDestinationAddImage(animatedGifFile, frame, frameDictionary as CFDictionary)
            }
        }
        
        CGImageDestinationFinalize(animatedGifFile)
        
        if let data = try? Data(contentsOf: destinationURL) {
            let animatedImage = NSUIImage(data: data)
            return animatedImage
        }
        return nil
    }
#endif
    
    public static func recordFrames(diameter: CGFloat, duration: Double) -> [CGImage] {
        let totalFrames = 20
        
        var frames: [CGImage] = []
        for i in 0..<totalFrames {
//            autoreleasepool {
#if os(iOS) || os(watchOS) || os(tvOS)
                frames.append(VinylGenerator.recordImage(diameter: diameter, frame: i).cgImage!)
#elseif os(macOS)
                frames.append(VinylGenerator.recordImage(diameter: diameter, frame: i).cgImage(forProposedRect: nil, context: nil, hints: nil)!)
#endif
//            }
        }
        return frames
    }
}
