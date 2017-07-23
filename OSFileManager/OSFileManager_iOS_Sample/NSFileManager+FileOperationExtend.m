//
//  NSFileManager+FileOperationExtend.m
//  Boobuz
//
//  Created by xiaoyuan on 2017/7/19.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import "NSFileManager+FileOperationExtend.h"
#import <objc/runtime.h>

@interface NSFileManager ()

@property (nonatomic, strong) NSOperationQueue *fileOperationQueue;

@end

@implementation NSFileManager (FileOperationExtend)

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize, NSError *error))copyHandler {
    __block BOOL res = NO;
    __block NSError *copyError = nil;
    [self.fileOperationQueue addOperationWithBlock:^{
        res = [self copyItemAtPath:srcPath toPath:dstPath error:&copyError];
    }];
    
    [self.fileOperationQueue addOperationWithBlock:^{
        [[self class] readFileSizeForFilePath:dstPath handler:^(BOOL isFinished, unsigned long long receivedFileSize) {
            if (copyHandler) {
                copyHandler(isFinished, receivedFileSize, copyError);
            }
        }];
    }];
    
    return res;
}

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize, NSError *error))moveHandler {
    __block BOOL res = NO;
    __block NSError *moveError = nil;
    [self.fileOperationQueue addOperationWithBlock:^{
        res = [self moveItemAtPath:srcPath toPath:dstPath error:&moveError];
    }];
    [self.fileOperationQueue addOperationWithBlock:^{
        [[self class] readFileSizeForFilePath:dstPath handler:^(BOOL isFinishedCopy, unsigned long long receivedFileSize) {
            if (moveHandler) {
                moveHandler(isFinishedCopy, receivedFileSize, moveError);
            }
        }];
    }];
    return res;
}


+ (void)readFileSizeForFilePath:(NSString *)filePath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize))handler {
    unsigned long long lastSize = 0;
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSInteger fileSize = [[fileAttrs objectForKey:NSFileSize] intValue];
    
    do {
        lastSize = fileSize;
        [NSThread sleepForTimeInterval:0.5];
        if (handler) {
            handler(NO, lastSize);
        }
        NSLog(@"文件正在写入, 上次写入大小:%llu, filePath:%@", lastSize, filePath);
        
         fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
         fileSize = [[fileAttrs objectForKey:NSFileSize] intValue];
         
        //fileSize = [filePath fileSize];
        
    } while (lastSize != fileSize);
    
    if (handler) {
        handler(YES, lastSize);
    }
    NSLog(@"文件写入完成, 总大小:%ld, filePath:%@", fileSize, filePath);
    
}


- (NSOperationQueue *)fileOperationQueue {
    NSOperationQueue *queue = objc_getAssociatedObject(self, _cmd);
    if (!queue) {
        queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 2;
        queue.name = @"com.Boobuz.FileOperationExtend_queue";
        objc_setAssociatedObject(self, _cmd, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return queue;
}

@end

