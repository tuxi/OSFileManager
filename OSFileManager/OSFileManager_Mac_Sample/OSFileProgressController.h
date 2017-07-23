//
//  OSFileProgressController.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "OSFileManager.h"

@interface OSFileProgressController : NSObject

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSArrayController *tasks;

@end
