//
//  OSFileOperationQueue.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSFileOperationQueue : NSObject

@property (nonatomic, strong) NSNumber *progress;

- (void)performQueue;

@end
