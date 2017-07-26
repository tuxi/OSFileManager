//
//  DirectoryWatcher.h
//  DirectoryWatcherDemo
//
//  Created by Ossey on 2017/7/20.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DirectoryWatcher;

@protocol DirectoryWatcherDelegate <NSObject>
@required
- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
@end

@interface DirectoryWatcher : NSObject
{
    id <DirectoryWatcherDelegate> __weak delegate;
    
    int dirFD;
    int kq;
    
    CFFileDescriptorRef dirKQRef;
}
@property (nonatomic, weak) id <DirectoryWatcherDelegate> delegate;
+ (DirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath directoryDidChange:(void (^)(DirectoryWatcher *folderWatcher))block;
+ (DirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id<DirectoryWatcherDelegate>)watchDelegate;
- (void)invalidate;
@end
