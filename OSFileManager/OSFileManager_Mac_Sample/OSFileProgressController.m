//
//  OSFileProgressController.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileProgressController.h"

static void * OSFileProgressControllerContext = &OSFileProgressControllerContext;

@implementation OSFileProgressController
{
    NSInteger _lastOperationCount;
    NSTimer *_displayUITimer;
//    OSFileManager *_fileManager;
}


- (void)awakeFromNib {
    [super awakeFromNib];
//    _fileManager = [OSFileManager defaultManager];
    _lastOperationCount = 0;
//    [self tasks];
//    [self addObserver:self forKeyPath:@"tasks.arrangedObjects" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    [OSFileManager defaultManager].totalProgressBlock = ^(NSProgress *progress) {
        NSLog(@"totalProgress:(%f)", progress.fractionCompleted);
        if (progress.fractionCompleted < 1.0) {
            [self startDisplayUITimer];
        } else {
            [_displayUITimer invalidate];
        }
    };
    
}

- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"tasks.arrangedObjects"];
//    [self removeObserver:self forKeyPath:@"fileManager.totalProgressValue"];
}

- (NSInteger)operationCount {
    return [self.tasks.arrangedObjects count];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    if ([keyPath isEqualToString:@"asks.arrangedObjects"]) {
//        if ([self operationCount] > 0 && _lastOperationCount == 0) {
//            [self startDisplayUITimer];
//        } else {
//            [_displayUITimer invalidate];
//        }
//    } else {
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
//}


- (void)startDisplayUITimer {
    if (!_displayUITimer) {
        _displayUITimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onShowUIDelayElapsed:) userInfo:nil repeats:NO];
    }
}

- (void)onShowUIDelayElapsed:(NSTimer *)timer {
    if ([self operationCount] > 0 && [OSFileManager defaultManager].totalProgressValue.doubleValue < 0.95) {
        [self.window orderFront:self];
    }
}

- (NSArrayController *)tasks {
    if (!_tasks) {
        _tasks = [NSArrayController new];
        [_tasks setObjectClass:NSClassFromString(@"OSFileOperation")];
        [_tasks setAutomaticallyPreparesContent:YES];
        [_tasks setAutomaticallyRearrangesObjects:YES];
        [_tasks bind:NSContentArrayBinding toObject:[OSFileManager defaultManager] withKeyPath:@"operations" options:nil];
        [_tasks prepareContent];
    }
    return _tasks;
}

@end
