//
//  RotatingCAView.swift
//  VinylView
//

import SwiftUI
import QuartzCore

// Applies a continuous rotation animation using CABasicAnimation directly on a native
// view layer, so CA transforms the pixel buffer of the subtree without triggering
// CALayerDelegate.display() — and therefore without triggering SwiftUI re-renders.
//
// Rotation phases:
//   stopped → rampingUp (easeIn, 2× spinDuration) → spinning (linear, infinite)
//           → rampingDown (easeOut, proportional) → stopped (identity, 0°)
//
// onStopped fires when the ramp-down animation fully completes, allowing the caller
// to stop any co-animating elements (e.g. the groove texture) in sync.

// MARK: - Shared Coordinator (cross-platform)

final class RotatingCACoordinator: NSObject, CAAnimationDelegate {
    weak var layer: CALayer?
    var onStopped: (() -> Void)?

    let spinDuration: Double
    let rampDuration: Double    // = spinDuration × 2; velocity matches at handoff

    enum State { case stopped, rampingUp, spinning, rampingDown }
    var state: State = .stopped

    init(spinDuration: Double) {
        self.spinDuration = spinDuration
        self.rampDuration = spinDuration * 2
    }

    func startSpinning() {
        guard state == .stopped else { return }
        state = .rampingUp
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = 0
        anim.toValue = fullRevolution
        anim.duration = rampDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        anim.isRemovedOnCompletion = false
        anim.delegate = self
        anim.setValue("rampUp", forKey: "name")
        layer?.add(anim, forKey: "continuousRotation")
    }

    func stopSpinning() {
        guard state == .spinning || state == .rampingUp else { return }
        state = .rampingDown
        guard let layer else { return }

        let currentAngle = (layer.presentation()?.value(forKeyPath: "transform.rotation.z") as? Double) ?? 0
        // Freeze model layer at the visual angle before swapping the animation
        layer.transform = layer.presentation()?.transform ?? layer.transform
        layer.removeAnimation(forKey: "continuousRotation")

        // Remaining fraction of the current revolution (0 = almost done, 1 = just started)
        let remaining = abs(fullRevolution - currentAngle) / abs(fullRevolution)
        let stopDuration = max(rampDuration * remaining, 0.4)

        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = currentAngle
        anim.toValue = fullRevolution   // complete the revolution → lands at 0°
        anim.duration = stopDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        anim.delegate = self
        anim.setValue("rampDown", forKey: "name")
        layer.add(anim, forKey: "continuousRotation")
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag else { return }
        switch anim.value(forKey: "name") as? String {
        case "rampUp" where state == .rampingUp:
            state = .spinning
            let steady = CABasicAnimation(keyPath: "transform.rotation.z")
            steady.fromValue = 0
            steady.toValue = fullRevolution
            steady.duration = spinDuration
            steady.repeatCount = .infinity
            steady.timingFunction = CAMediaTimingFunction(name: .linear)
            steady.isRemovedOnCompletion = false
            layer?.add(steady, forKey: "continuousRotation")
        case "rampDown" where state == .rampingDown:
            state = .stopped
            layer?.removeAnimation(forKey: "continuousRotation")
            layer?.transform = CATransform3DIdentity
            onStopped?()
        default:
            break
        }
    }

    // Direction: negative = clockwise in AppKit's Y-up coordinate space.
    // UIKit uses Y-down, so clockwise is positive — but CALayer's coordinate space
    // is always Y-up on both platforms, so negative is correct everywhere.
    private let fullRevolution = -Double.pi * 2
}

// MARK: - macOS

#if os(macOS)
import AppKit

final class _RotatingContainerView: NSView {
    var hostingView: NSHostingView<AnyView>?

    override var intrinsicContentSize: NSSize {
        hostingView?.fittingSize ?? super.intrinsicContentSize
    }
}

struct RotatingCAView: NSViewRepresentable {
    let isRotating: Bool
    let duration: Double
    let content: AnyView
    var onStopped: (() -> Void)?

    typealias Coordinator = RotatingCACoordinator

    func makeCoordinator() -> Coordinator { Coordinator(spinDuration: duration) }

    func makeNSView(context: Context) -> _RotatingContainerView {
        let container = _RotatingContainerView()
        container.wantsLayer = true

        let host = NSHostingView(rootView: content)
        host.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host)
        container.hostingView = host

        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateNSView(_ container: _RotatingContainerView, context: Context) {
        container.hostingView?.rootView = content
        context.coordinator.onStopped = onStopped

        // AppKit NSView-backed layers default to anchorPoint (0,0) — the bottom-left
        // corner — not (0.5, 0.5). Without fixing this, rotation happens around the
        // corner instead of the center. We shift position to compensate so the view
        // doesn't visually move.
        if let layer = container.layer {
            let target = CGPoint(x: 0.5, y: 0.5)
            let old = layer.anchorPoint
            if old != target {
                let sz = layer.bounds.size
                layer.position = CGPoint(
                    x: layer.position.x + (target.x - old.x) * sz.width,
                    y: layer.position.y + (target.y - old.y) * sz.height
                )
                layer.anchorPoint = target
            }
        }

        if context.coordinator.layer == nil {
            context.coordinator.layer = container.layer
        }

        if isRotating {
            context.coordinator.startSpinning()
        } else {
            context.coordinator.stopSpinning()
        }
    }
}

#elseif os(iOS) || os(tvOS)
import UIKit

struct RotatingCAView: UIViewRepresentable {
    let isRotating: Bool
    let duration: Double
    let content: AnyView
    var onStopped: (() -> Void)?

    typealias Coordinator = RotatingCACoordinator

    func makeCoordinator() -> Coordinator { Coordinator(spinDuration: duration) }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let host = UIHostingController(rootView: content)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        container.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.onStopped = onStopped

        if context.coordinator.layer == nil {
            context.coordinator.layer = container.layer
        }

        if isRotating {
            context.coordinator.startSpinning()
        } else {
            context.coordinator.stopSpinning()
        }
    }
}
#endif

extension View {
    func rotatingCA(_ isRotating: Bool, duration: Double, onStopped: (() -> Void)? = nil) -> some View {
        RotatingCAView(isRotating: isRotating, duration: duration, content: AnyView(self), onStopped: onStopped)
    }
}
