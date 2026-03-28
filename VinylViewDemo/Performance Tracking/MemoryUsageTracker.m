//
//  MemoryUsageTracker.m
//  VinylViewDemo
//
//  Created by Enie Weiß on 23.04.23.
//

#import "MemoryUsageTracker.h"
#import <mach/mach.h>

@implementation MemoryUsageTracker

+ (unsigned long long)currentMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr == KERN_SUCCESS) {
        return info.resident_size;
    } else {
        return 0;
    }
}

@end
