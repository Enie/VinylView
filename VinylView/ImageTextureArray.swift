//
//  ImageTextureArray.swift
//  VinylView
//
//  Created by Enie Weiß on 12.04.23.
//

import MetalKit

class ImageTextureArray {
    var textureArray: MTLTexture
    var count: Int

    init(device: MTLDevice, images: [CGImage]) throws {
        guard let firstImage = images.first else {
            fatalError("Empty image array")
        }

        count = images.count

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2DArray
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = firstImage.width
        textureDescriptor.height = firstImage.height
        textureDescriptor.arrayLength = images.count
        textureDescriptor.usage = .shaderRead
        textureDescriptor.storageMode = .shared
        
        if #available(macOS 12.5, *) {
//            textureDescriptor.compressionType = .lossless
        } else {
            // Fallback on earlier versions
        }

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create texture array")
        }
        textureArray = texture

        let bytesPerPixel = 4
        let region = MTLRegionMake2D(0, 0, firstImage.width, firstImage.height)

        for (index, image) in images.enumerated() {
            let rawData = UnsafeMutableRawPointer.allocate(byteCount: firstImage.width * firstImage.height * bytesPerPixel, alignment: 1)
            defer { rawData.deallocate() }

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: rawData, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * bytesPerPixel, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                fatalError("Failed to create CGContext")
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

            textureArray.replace(region: region, mipmapLevel: 0, slice: index, withBytes: rawData, bytesPerRow: image.width * bytesPerPixel, bytesPerImage: 0)
        }
    }
}
