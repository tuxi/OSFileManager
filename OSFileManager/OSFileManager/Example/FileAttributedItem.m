//
//  FileAttributedItem.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileAttributedItem.h"

@interface FileAttributedItem ()

@property (nonatomic, strong, class) FileAttributedItem *rootItem;
@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, copy) NSString *fullPath;
@property (nonatomic, copy) NSString *relativePath;
@property (nonatomic, strong) FileAttributedItem *parentItem;
@property (nonatomic, strong) NSMutableArray<FileAttributedItem *> *childrenItems;
@property (nonatomic, assign) BOOL isPackage;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation FileAttributedItem

- (instancetype)initWithPath:(NSString *)path parentItem:(FileAttributedItem *)parentItem {
    if (self = [super init]) {
        _relativePath = [path copy];
        _parentItem = parentItem;
        _fileManager = [NSFileManager new];
        [_fileManager fileExistsAtPath:[self fullPath] isDirectory:&_isDirectory];
        NSURL *url = [NSURL fileURLWithPath:[self fullPath] isDirectory:_isDirectory];
        NSNumber *isPackge;
        [url getResourceValue:&isPackge forKey:NSURLIsPackageKey error:nil];
        _isPackage = [isPackge boolValue];
        if (_isPackage) {
            _isDirectory = NO;
        }
    }
    return self;
}

- (NSString *)fullPath {
    if (!_parentItem) {
        return _relativePath;
    }
    _fullPath = [[_parentItem fullPath] stringByAppendingPathComponent:_relativePath];
    return _fullPath;
}

static FileAttributedItem *_rootItem = nil;
+ (FileAttributedItem *)rootItem {
    if (_rootItem == nil) {
        _rootItem = [[FileAttributedItem alloc] initWithPath:[@"~/Desktop" stringByExpandingTildeInPath] parentItem:nil];
    }
    return _rootItem;
}

+ (void)setRootItem:(FileAttributedItem *)rootItem {
    _rootItem = rootItem;
}

- (NSMutableArray<FileAttributedItem *> *)childrenItems {
    if (!_childrenItems) {
        BOOL isExist, isDirectory;
        isExist = [_fileManager fileExistsAtPath:[self fullPath] isDirectory:&isDirectory];
        if (isExist && isDirectory) {
            NSError *error = nil;
            NSURL *fileURL = [NSURL fileURLWithPath:[self fullPath]];
            NSArray<NSURL *> *subFiles = [_fileManager contentsOfDirectoryAtURL:fileURL
                                                     includingPropertiesForKeys:@[NSURLPathKey]
                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          error:&error];
            if (!error) {
                _childrenItems = [NSMutableArray arrayWithCapacity:subFiles.count];
                [subFiles enumerateObjectsUsingBlock:^(NSURL *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    FileAttributedItem *subFile = [[FileAttributedItem alloc] initWithPath:obj.path parentItem:self];
                    [_childrenItems addObject:subFile];
                }];
            }
        }
    }
    return _childrenItems;
}

- (NSString *)description {
    return [self relativePath];
}

@end
