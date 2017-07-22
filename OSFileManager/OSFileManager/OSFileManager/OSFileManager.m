//
//  OSFileManager.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileManager.h"
#include "copyfile.h"

#define TIME_REMAINING_SMOOTHING_FACTOR 0.2f

@interface OSFileManager ()

@property (nonatomic, strong) NSMutableArray *operations;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSArrayController *operationsController;
@property (nonatomic, strong) OSFileOperationCompletionHandler completionHandler;

@end

@interface OSFileOperation : NSOperation <OSFileOperation>

@property (nonatomic, copy) NSURL *sourceURL;
@property (nonatomic, copy) NSURL *dstURL;
@property (nonatomic, strong) NSNumber *sourceBytes;
@property (nonatomic, strong) NSNumber *copiedBytes;
@property (nonatomic, strong) NSNumber *progress;
@property (nonatomic, strong) NSNumber *secondsRemaining;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, copy) OSFileOperationCompletionHandler completionHandler;
@property (nonatomic, copy) OSFileOperationProgress progressBlock;

int copyFileCallBack(
 int what,
 int stage,
 copyfile_state_t state,
 const char *source,
 const char *destination,
 void *context);

@end

@implementation OSFileManager

////////////////////////////////////////////////////////////////////////
#pragma mark - initialized
////////////////////////////////////////////////////////////////////////


+ (OSFileManager *)defaultManager {
    static OSFileManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [OSFileManager new];
    });
    return _instance;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"totalProgress"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"totalSourceBytes", @"totalCopiedBytes"]];
    }
    return keyPaths;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [NSOperationQueue new];
        _maxConcurrentOperationCount = 2;
        _operationQueue.maxConcurrentOperationCount = _maxConcurrentOperationCount;
        _operations = [NSMutableArray array];
        
        [self bind:@"totalSourceBytes"
          toObject:self.operationsController
       withKeyPath:@"arrangedObjects.@sum.sourceBytes"
           options:nil];
        [self bind:@"totalCopiedBytes"
          toObject:self.operationsController
       withKeyPath:@"arrangedObjects.@sum.copiedBytes"
           options:nil];
        
    }
    return self;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    _maxConcurrentOperationCount = MIN(0, maxConcurrentOperationCount);
    self.operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (NSArrayController *)operationsController {
    if (!_operationsController) {
        _operationsController = [NSArrayController new];
        [_operationsController setObjectClass:[OSFileOperation class]];
        [_operationsController setAutomaticallyPreparesContent:YES];
        [_operationsController setAutomaticallyRearrangesObjects:YES];
        [_operationsController bind:NSContentArrayBinding toObject:self withKeyPath:@"operations" options:nil];
    }
    return _operationsController;
}

- (NSUInteger)pendingOperationCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFinished == NO"];
    return [self.operations filteredArrayUsingPredicate:predicate].count;
}

- (NSNumber *)totalProgress {
    float progress = 0.0;
    if (self.totalSourceBytes.unsignedLongLongValue > 0) {
        progress = self.totalCopiedBytes.doubleValue / self.totalSourceBytes.doubleValue;
    }
    return @(progress);
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)addOperationsObject:(OSFileOperation *)operation {
    [self.operations addObject:operation];
    [_operationQueue addOperation:operation];
}
- (void)addOperations:(NSArray *)operations {
    [self.operations addObjectsFromArray:operations];
    [_operationQueue addOperations:operations waitUntilFinished:NO];
}
- (void)removeOperationsObject:(OSFileOperation *)operation {
    [self.operations removeObject:operation];
}
- (void)removeObjectFromOperationsAtIndex:(NSUInteger)index {
    [self.operations removeObjectAtIndex:index];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////


- (void)copyItemAtURL:(NSURL *)srcURL
                toURL:(NSURL *)dstURL
             progress:(OSFileOperationProgress)progress
    completionHandler:(OSFileOperationCompletionHandler)handler {
    
    OSFileOperation *fileOperation = [[OSFileOperation alloc] initWithSourceURL:srcURL
                                                                         desURL:dstURL
                                                                       progress:progress
                                                              completionHandler:handler];
    if (fileOperation.isFinished) {
        return;
    }
    
    [self addOperationsObject:fileOperation];
    __weak OSFileOperation *weakOperation = fileOperation;
    fileOperation.completionBlock = ^{
        [self performSelectorOnMainThread:@selector(removeOperationsObject:)
                               withObject:weakOperation
                            waitUntilDone:NO];
    };
}


- (void)moveItemAtURL:(NSURL *)srcURL
                toURL:(NSURL *)dstURL
             progress:(OSFileOperationProgress)progress
    completionHandler:(OSFileOperationCompletionHandler)handler {
    
    OSFileOperation *fileOperation = [[OSFileOperation alloc] initWithSourceURL:srcURL
                                                                         desURL:dstURL
                                                                       progress:progress
                                                              completionHandler:handler];
    if (fileOperation.isFinished) {
        return;
    }
    
    [self addOperationsObject:fileOperation];
    
    __weak OSFileOperation *weakOperation = fileOperation;
    fileOperation.completionBlock = ^{
        if (weakOperation.isFinished && !weakOperation.error) {
            NSError *removeError = nil;
            [[NSFileManager new] removeItemAtURL:weakOperation.sourceURL error:&removeError];
            if (removeError) {
                NSLog(@"Error: remove file error:%@", removeError.localizedDescription);
            }
        }
        [self performSelectorOnMainThread:@selector(removeOperationsObject:)
                               withObject:weakOperation
                            waitUntilDone:NO];
    };
}

- (void)cancelAllOperation {
    [_operationQueue cancelAllOperations];
}


@end

@implementation OSFileOperation
{
    copyfile_state_t _copyfileState;
    BOOL _isFinished;
    BOOL _isExecuting;
    NSTimeInterval _startTimeStamp;
    NSTimeInterval _previousProgressTimeStamp;
    NSString *_previousOperationFilePath;
    OSFileInteger _previousReceivedCopiedBytes;
    
}

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
                           desURL:(NSURL *)desURL
                         progress:(OSFileOperationProgress)progress
                completionHandler:(OSFileOperationCompletionHandler)completionHandler {
    if (self = [super init]) {
        _sourceURL = sourceURL;
        _dstURL = desURL;
        _sourceBytes = @0;
        _copiedBytes = @0;
        _progress = @0;
        _secondsRemaining = @0;
        _fileManager = [NSFileManager new];
        _completionHandler = completionHandler;
        _progressBlock = progress;
        NSError *error = nil;
        _sourceBytes = [self caclulateFileToatalSizeByFilePath:_sourceURL.path error:&error];
        if (error) {
            [self performCompletionWithError:error];
        }
    }
    return self;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:NSStringFromSelector(@selector(progress))]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"sourceBytes", @"copiedBytes"]];
    }
    else if ([key isEqualToString:NSStringFromSelector(@selector(fileName))]) {
        keyPaths = [keyPaths setByAddingObject:@"sourceURL"];
    }
    return keyPaths;
    
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isCancelled {
  return [super isCancelled];
}

- (NSString *)fileName {
    return self.sourceURL.lastPathComponent;
}

- (NSNumber *)progress {
    float progress = 0.0;
    if (self.sourceBytes.unsignedLongLongValue > 0) {
        progress = (self.copiedBytes.unsignedIntegerValue / self.sourceBytes.unsignedIntegerValue) * 1.0;
    }
    return _progress = @(progress);
}

- (void)start {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        _previousProgressTimeStamp = _startTimeStamp = [[NSDate date] timeIntervalSince1970];
        _copyfileState = copyfile_state_alloc();
                NSError *error = nil;
        copyfile_state_set(_copyfileState, COPYFILE_STATE_STATUS_CB, &copyFileCallBack);
        copyfile_state_set(_copyfileState, COPYFILE_STATE_STATUS_CTX, (__bridge void *)self);
        
        const char *scourcePath = self.sourceURL.path.UTF8String;
        const char *dstPath = self.dstURL.path.UTF8String;
        // 执行copy文件，此方法会阻塞当前线程，直到文件拷贝完成为止
        int resCode = copyfile(scourcePath, dstPath, _copyfileState, [self flags]);
        // copy完成后，若进度不为1，再次检测下本地的文件
        if (![self.progress isEqualToNumber:@(1.0)]) {
            NSError *error = nil;
           self.copiedBytes = [self caclulateFileToatalSizeByFilePath:_dstURL.path error:&error];
            if (!error) {
                [self updateProgress];
            }
        }
        
        if (resCode != 0 && ![self isCancelled]) {
            NSString *errorMessage = [NSString stringWithCString:strerror(errno) encoding:NSUTF8StringEncoding];
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSFilePathErrorKey: errorMessage}];
            NSLog(@"%@", errorMessage);
        }
        copyfile_state_free(_copyfileState);
        [self performCompletionWithError:error];
    });
}

- (void)cancel {
    [super cancel];
    
    BOOL isExist = [_fileManager fileExistsAtPath:self.dstURL.path];
    NSError *removeError = nil;
    if (isExist) {
        [_fileManager removeItemAtURL:self.dstURL error:&removeError];
        if (removeError) {
            NSLog(@"Error: cancel copy or move error:%@", removeError.localizedDescription);
        }
    }
    
    [self performCompletionWithError:removeError];
}

- (NSNumber *)caclulateFileToatalSizeByFilePath:(NSString *)filePath error:(NSError **)error {
    NSError *attributesError = nil;
    NSDictionary *attributeDict = [_fileManager attributesOfItemAtPath:filePath error:&attributesError];
    if (attributesError) {
        if (error) {
            *error = attributesError;
        }
        NSLog(@"Error: %@", attributesError);
        return @(-1);
    }
    
    BOOL isExist = NO, isDirectory = NO;
    OSFileInteger totalSize = 0;
    isExist = [_fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (isDirectory) {
        NSArray *fileArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:filePath error:nil];
        NSEnumerator *fileEnumerator = [fileArray objectEnumerator];
        NSString *fileName = nil;
        OSFileInteger aFileSize = 0;
        while ((fileName = fileEnumerator.nextObject)) {
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[filePath stringByAppendingPathComponent:fileName] error:nil];
            aFileSize += fileDictionary.fileSize;
        }
        totalSize = aFileSize;
    } else {
        totalSize = [attributeDict fileSize];
    }
    
    return @(totalSize);
}

- (void)performCompletionWithError:(NSError *)error {
    @synchronized (self) {
        self.error = error;
        [self willChangeValueForKey:@"_isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"_isExecuting"];
        [self willChangeValueForKey:@"_isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"_isFinished"];
        
        if ([self isCancelled]) {
            self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        }
        self.completionHandler(self, error);
    }
}

- (copyfile_flags_t)flags {
    copyfile_flags_t flags = COPYFILE_ALL | COPYFILE_NOFOLLOW | COPYFILE_EXCL;
    
    BOOL isExist = NO, isDirectory = NO;
    isExist = [_fileManager fileExistsAtPath:self.sourceURL.path isDirectory:&isDirectory];
    if (isExist && isDirectory) {
        flags |= COPYFILE_RECURSIVE; // b |= b; 与 a = a|b; 等价，但前者可能效率更高
    }
    return flags;
}

int copyFileCallBack(int what, int stage, copyfile_state_t state, const char *path, const char *destination, void *context) {
    OSFileOperation *self = (__bridge OSFileOperation *)context;
    if (self.isCancelled) {
        NSLog(@"fil operation was cancelled");
        return COPYFILE_QUIT;
    }
    
    switch (what) {
        case COPYFILE_COPY_DATA:
            switch (stage) {
                case COPYFILE_PROGRESS: { // copy进度回调
                    // receivedCopiedBytes 回调每次一个文件已经copy到的大小
                    off_t receivedCopiedBytes = 0;
                    const int code = copyfile_state_get(state, COPYFILE_STATE_COPIED, &receivedCopiedBytes);
                    if (code == 0) {
                        [self updateStateWithCopiedBytes:receivedCopiedBytes path:@(path)];
                        [self updateProgress];
                    }
                    break;
                }
                case COPYFILE_ERR: {
                    return COPYFILE_QUIT;
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return COPYFILE_CONTINUE;
}

- (void)updateStateWithCopiedBytes:(OSFileInteger)receivedCopiedBytes path:(NSString *)source {
    if (![_previousOperationFilePath isEqualToString:source]) {
        _previousReceivedCopiedBytes = 0;
        _previousOperationFilePath = [source copy];
    }
    
    // copiedBytesOffset 计算每次copy了多少
    OSFileInteger copiedBytesOffset = receivedCopiedBytes - _previousReceivedCopiedBytes;
    _copiedBytes = @(_copiedBytes.unsignedLongLongValue + copiedBytesOffset);
    
    _previousReceivedCopiedBytes = receivedCopiedBytes;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    NSTimeInterval previousTransferRate = copiedBytesOffset / (now - _previousProgressTimeStamp);
    NSTimeInterval overallTransferRate = receivedCopiedBytes / (now - _startTimeStamp);
    NSTimeInterval averageTransferRate = TIME_REMAINING_SMOOTHING_FACTOR * previousTransferRate + ((1 - TIME_REMAINING_SMOOTHING_FACTOR) * overallTransferRate);
    _secondsRemaining = @((_sourceBytes.unsignedLongLongValue - receivedCopiedBytes) / averageTransferRate);
}

- (void)updateProgress {
    if (_progressBlock) {
        float progress = [self.progress floatValue];
        _progressBlock(progress);
    }
}


- (NSString *)description {
    return [NSString stringWithFormat:@"OSFileOperation:\nsourceURL:%@\ndstURL:%@", self.sourceURL, self.dstURL];
}

@end
