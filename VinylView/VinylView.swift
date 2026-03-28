//
//  VinylView.swift
//  VinylView
//
//  Created by Enie Weiß on 01.10.22.
//

import SwiftUI
import Combine

public enum VinylViewMode {
    case gif, gpu, memoryless
}

let FPS: Double = 30

public struct VinylView<Content>: View where Content : View {
#if os(iOS) || os(watchOS) || os(tvOS)
    public var label: UIImage?
    public var labelColor: UIColor?
    @State private var animatedImage: UIImage?
    @State private var frames = [UIImage]()
#elseif os(macOS)
    public var label: NSImage?
    public var labelColor: NSColor?
    @State private var animatedImage: NSImage?
    @State private var frames = [NSImage]()
#endif
    @State private var animationFrames: [CGImage] = []
    @State private var textureIsAnimating: Bool = false
    public var diameter: CGFloat
    public var tracksCount: Int = 5
    @State public var isPlaying: Bool = false
    public var mode: VinylViewMode
    public var content: (() -> Content)
    
    @ObservedObject var vinylGenerator = VinylGenerator()
    
    public var trackDivisions: some View {
        let halfDiameter = diameter/2
        let thirdDiameter = (diameter*0.33) / (Double(tracksCount-1))
        return ForEach((1...tracksCount-1), id: \.self) { index in
            Circle()
                .stroke(lineWidth: 2)
                .foregroundColor(.black)
                .frame(width: halfDiameter + thirdDiameter*Double(index),
                       height: halfDiameter + thirdDiameter*Double(index))
        }
    }
    
    public init(label: NSImage? = nil, labelColor: NSColor? = nil, diameter: CGFloat, tracksCount: Int, isPlaying: Bool, mode: VinylViewMode = .gif, content: @escaping (() -> Content)) {
        self.label = label
        self.labelColor = labelColor
        self.diameter = diameter
        self.tracksCount = tracksCount
        self.isPlaying = isPlaying
        self.content = content
        self.mode = mode
    }
    
    var recordView: some View {
        ZStack {
            if mode == .gif,
               let image = animatedImage {
                AnimatedImage(animationImage: image, isAnimating: textureIsAnimating)
                    .rotationEffect(Angle(degrees: Double(90)))
            } else if mode == .gpu,
               animationFrames.count > 0 &&
                animationFrames.first!.width & animationFrames.first!.height != 0 {
                AnimatedMetalImage(images: animationFrames, isPlaying: textureIsAnimating)
                    .frame(minWidth: diameter, minHeight: diameter)
            } else if mode == .memoryless {
                MetalView(renderer: vinylGenerator, isPlaying: textureIsAnimating)
                    .frame(minWidth: diameter, minHeight: diameter)
            }
            Circle()
                .foregroundColor(.black)
                .frame(width: diameter/2, height: diameter/2)
            trackDivisions
            Circle()
                .stroke(lineWidth: diameter*0.05)
                .foregroundColor(.black)
                .frame(width: diameter, height: diameter)
                .overlay(
                    // highlight
                    Circle()
                        .stroke(Color(red: 236/255, green: 234/255, blue: 235/255).opacity(0.01),
                                lineWidth: 1)
                        .shadow(color: Color(red: 192/255, green: 189/255, blue: 191/255).opacity(0.5),
                                radius: 0, x: 0, y: 1)
                        .clipShape(
                            Circle()
                        )
                )
        }
    }

    public var body: some View {
        ZStack(alignment: .center) {
            recordView
            VinylLabelView(label: label, labelColor: labelColor, diameter: diameter, tracksCount: tracksCount, isPlaying: isPlaying, onStopped: {
                textureIsAnimating = false
            }) {
                content()
            }
        }
        .frame(width: diameter, height: diameter)
        .cornerRadius(diameter)
        .onChange(of: isPlaying) { playing in
            if playing { textureIsAnimating = true }
            // When stopping, textureIsAnimating is set to false by onStopped
            // once the CA ramp-down animation finishes — not immediately here.
        }
        .onAppear {
            autoreleasepool {
                animatedImage = nil
                animationFrames.removeAll()
                
                if mode == .gif {
                    animatedImage = VinylGenerator.recordAnimation(diameter: diameter, duration: 1)
                } else if mode == .gpu {
                    animationFrames.removeAll()
                    animationFrames.append(contentsOf: VinylGenerator.recordFrames(diameter: diameter, duration: 1))
                } else if mode == .memoryless {
                    vinylGenerator.diameter = diameter
                }
            }
        }
        .onDisappear {
            autoreleasepool {
                animationFrames.removeAll()
                animatedImage = nil
            }
        }
        .onTapGesture {
            isPlaying.toggle()
        }
    }
}

struct VinylView_Previews: PreviewProvider {
    static var previews: some View {
        VinylView(labelColor: .orange,
                  diameter: 300,
                  tracksCount: 4,
                  isPlaying: false,
                  mode: .memoryless) {
            VStack(alignment: .leading) {
                Text("Side A").fontWeight(.bold)
                Text("1. Beauty and the Beast").font(.system(size: 5))
                Text("2. Joe the Lion").font(.system(size: 5))
                Text("3. \"Heroes\"").font(.system(size: 5))
                Text("4. Sons of the Silent Age").font(.system(size: 5))
            }
        }
    }
}
