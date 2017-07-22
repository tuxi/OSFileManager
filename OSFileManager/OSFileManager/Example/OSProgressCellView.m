//
//  OSProgressCellView.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSProgressCellView.h"

@implementation OSProgressCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Drawing code here.
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"operationModel"]) {
        keyPaths = [keyPaths setByAddingObject:@"objectValue"];
    }
    else if ([key isEqualToString:@"progressString"]) {
    
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"operationModel.sourceTotalBytes", @"operationModel.receivedCopiedBytes"]];
    }
    return keyPaths;
    
}

- (id<OSFileOperation>)operationModel {
    return self.objectValue;
}

- (NSString *)progressString {
   NSString *receivedCopiedBytesStr = [NSByteCountFormatter stringFromByteCount:self.operationModel.receivedCopiedBytes
                                   countStyle:NSByteCountFormatterCountStyleFile];
    NSString *totalBytesStr = [NSByteCountFormatter stringFromByteCount:self.operationModel.sourceTotalBytes countStyle:NSByteCountFormatterCountStyleFile];
    return [NSString stringWithFormat:@"[%@ of %@] -- [progress: %f]", receivedCopiedBytesStr, totalBytesStr, self.operationModel.progress.fractionCompleted];
}

- (void)cancel {
    [self.operationModel cancel];
}

@end
