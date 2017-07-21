//
//  FileAttributedItem.h
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileAttributedItem : NSObject

@property (nonatomic, strong, readonly, class) FileAttributedItem *rootItem;
@property (nonatomic, assign, readonly) BOOL isDirectory;
@property (nonatomic, copy, readonly) NSString *fullPath;
@property (nonatomic, copy, readonly) NSString *relativePath;
@property (nonatomic, strong, readonly) NSMutableArray<FileAttributedItem *> *childrenItems;

@end
