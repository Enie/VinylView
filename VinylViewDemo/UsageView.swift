//
//  UsageView.swift
//  VinylViewDemo
//
//  Created by Enie Weiß on 12.04.23.
//

import SwiftUI

struct UsageView: View {
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State var memoryUsage: Double = 0
    @State var CPUUsage: Double = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("CPU Usage (user): \(CPUUsage, specifier: "%.1f") %")
                Text("Memory Usage: \(memoryUsage, specifier: "%.2f") MB")
            }
            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.1))
        .cornerRadius(16)
        .onReceive(timer) { _ in
            memoryUsage = Double(MemoryUsageTracker.currentMemoryUsage())/(1024*1024)
            CPUUsage = CPUUsageTracker.currentCPUUsage()*100
        }
    }
}

struct UsageView_Previews: PreviewProvider {
    static var previews: some View {
        UsageView()
    }
}
