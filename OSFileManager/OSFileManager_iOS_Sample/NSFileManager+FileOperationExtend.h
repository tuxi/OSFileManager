//
//  NSFileManager+FileOperationExtend.h
//  Boobuz
//
//  Created by xiaoyuan on 2017/7/19.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (FileOperationExtend)

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize, NSError *error))moveHandler;

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize, NSError *error))copyHandler;

+ (void)readFileSizeForFilePath:(NSString *)filePath handler:(void (^)(BOOL isFinished, unsigned long long receivedFileSize))handler;

@end
