//
//  OSFileOperationQueue.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSFileManager.h"

@interface OSFileOperationQueue : NSObject

@property (nonatomic, strong) NSNumber *progress;
@property (nonatomic, assign) NSUInteger maxConcurrentOperationCount;
@property (nonatomic, strong) OSFileOperationProgress totalProgressBlock;

- (void)performQueue;

@end
