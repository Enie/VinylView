import MetalKit
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class MTLFilter {
    static func textureFrom(texture:MTLTexture, device: MTLDevice, size: MTLSize, isOutput: Bool = false) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = size.width
        descriptor.height = size.height
        descriptor.usage = MTLTextureUsage([.shaderRead, .shaderWrite, .renderTarget, .pixelFormatView])
        return device.makeTexture(descriptor: descriptor)
    }
    
#if os(iOS) || os(watchOS) || os(tvOS)
    static func radialBlur (uiImage: UIImage) -> UIImage {
        guard let device = MTLCreateSystemDefaultDevice(),
              let cgInput = uiImage.cgImage,
              let input = try? MTKTextureLoader(device: device).newTexture(cgImage: cgInput),
              let result = radialBlur(texture: input),
              let ciImage = CIImage(mtlTexture: result)
        else {
            return uiImage.copy() as! UIImage
        }
        
        return UIImage(ciImage: ciImage)
    }
#else
    static func radialBlur (nsImage: NSImage) -> NSImage {
        guard let device = MTLCreateSystemDefaultDevice(),
              let cgInput = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let input = try? MTKTextureLoader(device: device).newTexture(cgImage: cgInput),
              let result = radialBlur(texture: input),
              let ciImage = CIImage(mtlTexture: result)
        else {
            return nsImage.copy() as! NSImage
        }
        
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
#endif
    
    static func radialBlur(texture: MTLTexture) -> MTLTexture?
    {
        let height = texture.height
        let width = texture.width
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: Bundle(for: self)),
              let function = library.makeFunction(name: "radialBlur"),
              let state = try? device.makeComputePipelineState(function: function),
              let commandQueue = device.makeCommandQueue(),
              let buffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = buffer.makeComputeCommandEncoder(),
              let result = MTLFilter.textureFrom(texture: texture, device: device, size: MTLSizeMake(width, height, 0))
        else {
            return nil
        }

        let threadGroupWidth = 32
        let threadGroupHeight = 32

        let threadsPerGroup = MTLSizeMake(threadGroupWidth, threadGroupHeight, 1)
        let numThreadgroups = MTLSizeMake(width/threadsPerGroup.width + 1, height/threadsPerGroup.height + 1, 1)

        var blurSize: Float = 0.1
        computeEncoder.setComputePipelineState(state)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setTexture(result, index: 1)
        computeEncoder.setBytes(&blurSize, length: MemoryLayout<Float>.size, index: 0)
        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        buffer.commit()
        buffer.waitUntilCompleted()
        
        return result
    }
}

