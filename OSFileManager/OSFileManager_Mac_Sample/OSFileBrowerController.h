//
//  OSFileBrowerController.h
//  OSFileManager
//
//  Created by alpface on 2017/7/21.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "OSFileOperationQueue.h"

@interface OSFileBrowerController : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource>
@property (weak) IBOutlet NSOutlineView *leftOutlineView;
@property (weak) IBOutlet NSOutlineView *rightOutlineView;
@property (weak) IBOutlet OSFileOperationQueue *fileOperationQueue;
@property (weak) IBOutlet NSWindow *progressWindow;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *fileNameLabel;
@property (weak) IBOutlet NSTextField *progressTextLabel;

@end
