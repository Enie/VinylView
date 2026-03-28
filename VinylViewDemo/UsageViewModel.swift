//
//  UsageViewModel.swift
//  VinylViewDemo
//
//  Created by Enie Weiß on 12.04.23.
//

import SwiftUI
import Combine
import Metal
import System

class UsageViewModel: ObservableObject {
    @Published var cpuUsage: (system: Double, user: Double, idle : Double, nice: Double) = (0,0,0,0)
    @Published var memoryUsage: Float = 0
    var loadPrevious: host_cpu_load_info?
    
    private var updateTimer: Timer?
    
    func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateUsageData()
        }
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateUsageData() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
    }
    
    func hostCPULoadInfo() -> host_cpu_load_info? {
        
        let  HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        
        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        if result != KERN_SUCCESS{
            print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
            return nil
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    public func getCPUUsage() -> (system: Double, user: Double, idle : Double, nice: Double){
        let load = hostCPULoadInfo();
        
        if loadPrevious == nil {
            loadPrevious = load!
            return (0,0,0,0)
        }
        
        let usrDiff: Double = Double((load?.cpu_ticks.0)! - loadPrevious!.cpu_ticks.0);
        let systDiff = Double((load?.cpu_ticks.1)! - loadPrevious!.cpu_ticks.1);
        let idleDiff = Double((load?.cpu_ticks.2)! - loadPrevious!.cpu_ticks.2);
        let niceDiff = Double((load?.cpu_ticks.3)! - loadPrevious!.cpu_ticks.3);
        
        let totalTicks = usrDiff + systDiff + idleDiff + niceDiff

        let sys = systDiff / totalTicks * 100.0
        let usr = usrDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        return (sys, usr, idle, nice);
    }
    
    private func getMemoryUsage() -> Float {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kernReturn = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kernReturn == KERN_SUCCESS {
            return Float(taskInfo.resident_size) / (1024 * 1024) // Return memory usage in MB
        } else {
            return 0
        }
    }
}
