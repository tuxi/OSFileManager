//
//  OSProgressCellView.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OSFileManager.h"

@interface OSProgressCellView : NSTableCellView

@property (nonatomic, strong) id<OSFileOperation> operationModel;
@property (nonatomic, copy) NSString *progressString;

@end
