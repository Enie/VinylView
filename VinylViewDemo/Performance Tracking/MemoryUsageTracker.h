//
//  MemoryUsageTracker.h
//  VinylViewDemo
//
//  Created by Enie Weiß on 23.04.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemoryUsageTracker : NSObject

+ (unsigned long long)currentMemoryUsage;

@end

NS_ASSUME_NONNULL_END
