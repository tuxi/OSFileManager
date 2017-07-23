//
//  OSFileOperationQueue.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileOperationQueue.h"
#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    CopyOperation,
    MoveOperation,
} OSFileOperationMode;

static void *OSFileQueueItemsProcessingControllerContext = &OSFileQueueItemsProcessingControllerContext;
static void *OSFileQueueItemFinishedContext = &OSFileQueueItemFinishedContext;

@interface OSFileOperationRequest : NSObject

@property (nonatomic, copy) NSURL *sourceURL;
@property (nonatomic, copy) NSURL *dstURL;
@property (nonatomic, copy) OSFileOperationCompletionHandler completionHandler;
@property (nonatomic, copy) OSFileOperationProgress progressBlock;
@property (nonatomic, assign) OSFileOperationMode operationMode;

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
                           desURL:(NSURL *)desURL
                    operationMode:(OSFileOperationMode)operationMode
                         progress:(OSFileOperationProgress)progress
                completionHandler:(OSFileOperationCompletionHandler)completionHandler;
@end

@interface OSFileOperationQueue ()

@property (nonatomic, strong) NSArrayController *itemsProcessingController;
@property (nonatomic, strong) OSFileManager *fileManager;

@end

@implementation OSFileOperationQueue
{
    NSMutableArray<OSFileOperationRequest *> *_operationRequests;
    /// 要处理的request数量
    NSInteger _numberOfItemsToProcess;
    /// 已经处理的request数量
    NSInteger _numberOfItemsProcessed;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileManager = [OSFileManager new];
        self.maxConcurrentOperationCount = 2;
        _fileManager.totalProgressBlock = self.totalProgressBlock;
        [self.itemsProcessingController addObserver:self
                                         forKeyPath:@"arrangedObjects.@count"
                                            options:NSKeyValueObservingOptionNew
                                            context:OSFileQueueItemsProcessingControllerContext];
        _operationRequests = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self.itemsProcessingController removeObserver:self
                                        forKeyPath:@"arrangedObjects.@count"
                                           context:OSFileQueueItemsProcessingControllerContext];
}

- (void)setMaxConcurrentOperationCount:(NSUInteger)maxConcurrentOperationCount {
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    _fileManager.maxConcurrentOperationCount = maxConcurrentOperationCount;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL progress:(OSFileOperationProgress)progress completionHandler:(OSFileOperationCompletionHandler)handler {
    @synchronized (_operationRequests) {
        
        OSFileOperationRequest *request = [self operationRequestBySrcURL:srcURL dstURL:dstURL];
        if (request) {
            NSLog(@"request exist (srcPath:%@-dstPath:%@)", srcURL.path, dstURL.path);
            return;
        }
        
        [_operationRequests addObject:[[OSFileOperationRequest alloc] initWithSourceURL:srcURL
                                                                                 desURL:dstURL
                                                                          operationMode:CopyOperation
                                                                               progress:progress
                                                                      completionHandler:handler]];

    }
}

- (void)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL progress:(OSFileOperationProgress)progress completionHandler:(OSFileOperationCompletionHandler)handler {
    
    @synchronized (_operationRequests) {
        
        OSFileOperationRequest *request = [self operationRequestBySrcURL:srcURL dstURL:dstURL];
        if (request) {
            NSLog(@"request exist (srcPath:%@-dstPath:%@)", srcURL.path, dstURL.path);
            return;
        }
        [_operationRequests addObject:[[OSFileOperationRequest alloc] initWithSourceURL:srcURL
                                                                                 desURL:dstURL
                                                                          operationMode:MoveOperation
                                                                               progress:progress
                                                                      completionHandler:handler]];

    }
}

- (void)performQueue {
    @synchronized (_operationRequests) {
        _numberOfItemsToProcess = _operationRequests.count + [_itemsProcessingController.arrangedObjects count];
        [self updateProcessItemsProgress];
        
        NSInteger count = MIN([_operationRequests count], self.maxConcurrentOperationCount ?: INT_MAX);
        for (NSInteger i = 0; i < count; ++i) {
            if (!_operationRequests.count) {
                return;
            }
            
            OSFileOperationRequest * _Nonnull obj = _operationRequests[i];
            id op = nil;
            if (obj.operationMode == CopyOperation) {
              op = [_fileManager copyItemAtURL:obj.sourceURL
                                      toURL:obj.dstURL
                                   progress:obj.progressBlock
                          completionHandler:obj.completionHandler];
            }
            else if (obj.operationMode == MoveOperation) {
               op = [_fileManager moveItemAtURL:obj.sourceURL
                                      toURL:obj.dstURL
                                   progress:obj.progressBlock
                          completionHandler:obj.completionHandler];
            }
            [op addObserver:self forKeyPath:@"isFinished"
                    options:NSKeyValueObservingOptionNew
                    context:OSFileQueueItemFinishedContext];

        }
        
    }
}

- (OSFileOperationRequest *)operationRequestBySrcURL:(NSURL *)srcURL dstURL:(NSURL *)dstURL {
    @synchronized (_operationRequests) {
        NSUInteger foundIdxInOperations = [_operationRequests indexOfObjectPassingTest:^BOOL(OSFileOperationRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL res = [obj.sourceURL.path isEqualToString:srcURL.path] && [obj.dstURL.path isEqualToString:dstURL.path];
            if (res) {
                *stop = YES;
            }
            return res;
        }];
        if (foundIdxInOperations != NSNotFound) {
            return [_operationRequests objectAtIndex:foundIdxInOperations];
        }
        return nil;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == OSFileQueueItemsProcessingControllerContext && object == self.itemsProcessingController) {
        if ([keyPath isEqualToString:@"arrangedObjects.@count"]) {
            [self updateProcessItemsProgress];
        }
    }
    else if (context == OSFileQueueItemFinishedContext) {
        if ([keyPath isEqualToString:@"isFinished"]) {
            [object removeObserver:self forKeyPath:keyPath context:OSFileQueueItemFinishedContext];
            id <OSFileOperation> op = object;
            NSUInteger foundIdxInOperations = [_operationRequests indexOfObjectPassingTest:^BOOL(OSFileOperationRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL res = [obj.sourceURL.path isEqualToString:op.sourceURL.path] && [obj.dstURL.path isEqualToString:op.dstURL.path];
                if (res) {
                    *stop = YES;
                }
                return res;
            }];
            if (foundIdxInOperations != NSNotFound) {
                [_operationRequests removeObjectAtIndex:foundIdxInOperations];
            }
            [self performQueue];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}



- (NSArrayController *)itemsProcessingController {
    if (!_itemsProcessingController) {
        _itemsProcessingController = [NSArrayController new];
        [_itemsProcessingController setObjectClass:NSClassFromString(@"OSFileOperation")];
        [_itemsProcessingController setAutomaticallyPreparesContent:YES];
        [_itemsProcessingController setAutomaticallyRearrangesObjects:YES];
        [_itemsProcessingController bind:NSContentArrayBinding toObject:self withKeyPath:@"fileManager.operations" options:nil];
    }
    return _itemsProcessingController;
}


- (void)updateProcessItemsProgress {
    _numberOfItemsProcessed = _numberOfItemsToProcess - [self.itemsProcessingController.arrangedObjects count];
    if (_numberOfItemsToProcess == 0) {
        self.progress = @0;
    } else {
        self.progress = @(_numberOfItemsProcessed / (_numberOfItemsToProcess * 1.0));
    }
}

@end

@implementation OSFileOperationRequest

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
                           desURL:(NSURL *)desURL
                    operationMode:(OSFileOperationMode)operationMode
                         progress:(OSFileOperationProgress)progress
                completionHandler:(OSFileOperationCompletionHandler)completionHandler {
    if (self = [super init]) {
        _sourceURL = sourceURL;
        _dstURL = desURL;
        _progressBlock = progress;
        _completionHandler = completionHandler;
        _operationMode = operationMode;
    }
    return self;
}

@end

