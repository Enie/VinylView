// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VinylView",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "VinylView", targets: ["VinylView"]),
    ],
    targets: [
        .target(
            name: "VinylView",
            path: "VinylView",
            exclude: [
                // Framework umbrella header — not needed for SPM
                "VinylView.h",
                // ObjC implementation whose required header (NSImage+MTLTexture.h) no longer
                // exists; Image+MTLTexture.swift provides the same functionality in Swift
                "NSImage+MTLTexture4.m",
            ],
            resources: [
                // Metal shader sources — SPM compiles these and makes them available
                // via Bundle.module (see BundleToken.swift)
                .process("Shaders"),
            ]
        ),
        .testTarget(
            name: "VinylViewTests",
            dependencies: ["VinylView"],
            path: "VinylViewTests"
        ),
    ]
)
