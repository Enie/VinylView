//
//  ContentView.swift
//  VinylViewDemo
//
//  Created by Enie Weiß on 12.04.23.
//

import SwiftUI
import VinylView

struct ContentView: View {
    @StateObject var viewModel = UsageViewModel()
    @State var selection = 0
    
    var label: some View {
        VStack(alignment: .leading) {
            Text("Side A").fontWeight(.bold)
            Text("1. Beauty and the Beast").font(.system(size: 5))
            Text("2. Joe the Lion").font(.system(size: 5))
            Text("3. \"Heroes\"").font(.system(size: 5))
            Text("4. Sons of the Silent Age").font(.system(size: 5))
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            UsageView()
                .shadow(radius: 4)
            
            TabView {
                VinylView(labelColor: .controlAccentColor,
                          diameter: 300,
                          tracksCount: 4,
                          isPlaying: false,
                          mode: .memoryless) {
                    label
                }
                    .frame(width: 300, height: 300)
                    .tabItem {
                        Label("Memoryless", systemImage: "tray.and.arrow.down.fill")
                    }
                VinylView(labelColor: .controlAccentColor,
                          diameter: 300,
                          tracksCount: 4,
                          isPlaying: false,
                          mode: .gpu) {
                    label
                }
                  .tabItem {
                      Label("GPU", systemImage: "tray.and.arrow.down.fill")
                  }
                VinylView(labelColor: .controlAccentColor,
                          diameter: 300,
                          tracksCount: 4,
                          isPlaying: false,
                          mode: .gif) {
                    label
                }
                  .tabItem {
                      Label("GIF", systemImage: "tray.and.arrow.down.fill")
                  }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
