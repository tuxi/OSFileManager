//
//  OSFileBrowerController.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileBrowerController.h"
#import "FileAttributedItem.h"
#import "OSFileManager.h"

@interface OSFileBrowerController ()

/** 正在拖拽的文件 */
@property (nonatomic, strong) NSArray<FileAttributedItem *> *draggingItems;
/** 当前拖拽松开文件 */
@property (nonatomic, strong) FileAttributedItem *currentDropItem;

@end

@implementation OSFileBrowerController

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *srcURL = [NSURL fileURLWithPath:@"/Users/mofeini/Desktop/trunk4"];
        NSURL *dstURL = [NSURL fileURLWithPath:@"/Users/mofeini/Desktop/trunk5"];
        [[OSFileManager defaultManager] copyItemAtURL:srcURL toURL:dstURL progress:^(NSProgress *progress) {
            
            NSLog(@"%f", progress.fractionCompleted);
        } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
            
        }];
        
        [OSFileManager defaultManager].totalProgressBlock = ^(NSProgress *progress) {
            NSLog(@"%f", progress.fractionCompleted);
        };
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // 对leftOutlineView进行注册拖放事件的监听
    [self.leftOutlineView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
    [self.leftOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    
    [self.rightOutlineView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
    [self.rightOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSOutlineViewDataSource
////////////////////////////////////////////////////////////////////////

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(nonnull NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(nonnull NSArray *)draggedItems {
    // 正在拖动的items
    _draggingItems = [draggedItems mutableCopy];
    
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    
    // 拖拽结束后 将拖拽的文件copy到目标文件夹中
    [_draggingItems enumerateObjectsUsingBlock:^(FileAttributedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
    }];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    _currentDropItem = item;
    return index == -1 ? NSDragOperationNone : NSDragOperationCopy;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    
    NSMutableArray *urls = [NSMutableArray array];
    
    [items enumerateObjectsUsingBlock:^(FileAttributedItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [urls addObject:[NSURL fileURLWithPath:obj.fullPath]];
    }];
    [pasteboard writeObjects:urls];
    return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return !item ? 1 : [[item childrenItems] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [[item childrenItems] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return !item ? [FileAttributedItem rootItem] : [[item childrenItems] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
}

@end
