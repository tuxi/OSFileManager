//
//  OSFileOperationQueue.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileManager.h"

@interface OSFileOperationQueue : OSFileManager

@property (nonatomic, strong) NSNumber *progress;

- (void)performQueue;

@end
