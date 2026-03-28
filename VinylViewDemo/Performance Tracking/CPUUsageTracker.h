//
//  CPUUsageTracker.h
//  VinylViewDemo
//
//  Created by Enie Weiß on 23.04.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPUUsageTracker : NSObject

+ (double)currentCPUUsage;

@end

NS_ASSUME_NONNULL_END
