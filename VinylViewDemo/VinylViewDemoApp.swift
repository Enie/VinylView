//
//  VinylViewDemoApp.swift
//  VinylViewDemo
//
//  Created by Enie Weiß on 12.04.23.
//

import SwiftUI

@main
struct VinylViewDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
            .windowToolbarStyle(UnifiedWindowToolbarStyle() )
            .windowStyle(.hiddenTitleBar)
    }
}
