//
//  RotatingViewModifier.swift
//  VinylView
//
//  Created by Enie Weiß on 10.04.23.
//

import SwiftUI

import SwiftUI

struct RotatingViewModifier: ViewModifier {
    let isRotating: Bool
    let duration: Double
    let angle: Angle
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(isRotating ? angle : .zero)
            .animation(isRotating ? Animation.linear(duration: duration)
                .repeatForever(autoreverses: false) : .default, value: isRotating)
    }
}

extension View {
    func rotating(_ isRotating: Bool = false, duration: Double = 1, angle: Angle = .degrees(360)) -> some View {
        self.modifier(RotatingViewModifier(isRotating: isRotating, duration: duration, angle: angle))
    }
}
