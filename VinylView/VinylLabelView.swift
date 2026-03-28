//
//  VinylLabelView.swift
//  VinylView
//
//  Created by Enie Weiß on 25.04.23.
//

import SwiftUI

struct VinylLabelView<Content>: View where Content : View {
#if os(iOS) || os(watchOS) || os(tvOS)
    var label: UIImage?
    var labelColor: UIColor?
#elseif os(macOS)
    var label: NSImage?
    var labelColor: NSColor?
#endif
    var diameter: CGFloat
    var tracksCount: Int = 5
    var isPlaying: Bool = false
    var content: (() -> Content)
    
    let timer = Timer.publish(every: 1/FPS, on: .main, in: .common).autoconnect()
    @State private var rotation = 0.0
    
    var body: some View {
        Group {
#if os(iOS) || os(watchOS) || os(tvOS)
            Image(uiImage: label ?? UIImage.imageWith(color: labelColor ?? .green))
                .resizable()
                .frame(width: diameter/3, height: diameter/3)
                .cornerRadius(diameter/6)
#elseif os(macOS)
            Image(nsImage: label ?? NSImage.imageWith(color: labelColor ?? .green))
                .resizable()
                .frame(width: diameter/3, height: diameter/3)
                .cornerRadius(diameter/6)
#endif
            content()
                .frame(width: diameter/3, height: diameter/3)
        }
        .rotationEffect(Angle(degrees: rotation ))
        .overlay(
            ZStack {
                // highlight
                Circle()
                    .stroke(Color(red: 236/255, green: 234/255, blue: 235/255).opacity(0.01),
                            lineWidth: 1)
                    .shadow(color: Color(red: 192/255, green: 189/255, blue: 191/255).opacity(0.5),
                            radius: 0, x: 0, y: 0.5)
                    .clipShape(
                        Circle()
                    )
                    .frame(width: diameter/3, height: diameter/3)
                Circle()
                    .fill(.black)
                    .frame(width: diameter*0.02, height: diameter*0.02)
                    .shadow(color: .white.opacity(0.5), radius: 0.25, y: 1)
                // shadow
                Circle()
                    .fill(.black)
                    .frame(width: diameter*0.02, height: diameter*0.02)
                    .shadow(color: .black.opacity(0.33), radius: 0.25, y: -1)
            }
        )
        .onReceive(timer) { _ in
            if isPlaying {
                self.rotation += 270/FPS // 270 degrees per second
            }
        }
    }
}

struct VinylLabelView_Previews: PreviewProvider {
    static var previews: some View {
        VinylLabelView(diameter: 300) {
            Text("Hallo")
        }
    }
}
