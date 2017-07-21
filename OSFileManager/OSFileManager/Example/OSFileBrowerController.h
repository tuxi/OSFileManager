//
//  OSFileBrowerController.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface OSFileBrowerController : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource>
@property (weak) IBOutlet NSOutlineView *leftOutlineView;
@property (weak) IBOutlet NSOutlineView *rightOutlineView;

@end
