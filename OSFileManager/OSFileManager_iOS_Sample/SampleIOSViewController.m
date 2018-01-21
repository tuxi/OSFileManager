//
//  SampleIOSViewController.m
//  OSFileManager_iOS_Sample
//
//  Created by alpface on 2017/7/23.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "SampleIOSViewController.h"
#import "OSFileManager.h"
#import "FoldersViewController.h"

#define kDoucmentPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
#define kCopyDirectory [kDoucmentPath stringByAppendingPathComponent:@"copy"]

@interface SampleIOSViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIProgressView *totalProgress;
@property (strong) id<OSFileOperation> bidOperation;

@end

@implementation SampleIOSViewController



- (IBAction)samllFileCopy:(id)sender {
    
    [self createCopyDstFolder];
    
    NSURL *sourceURL = [NSURL fileURLWithPath:[kDoucmentPath stringByAppendingPathComponent:@"testcopy"]];
    NSURL *dstURL = [NSURL fileURLWithPath:kCopyDirectory];
    [[OSFileManager defaultManager] copyItemAtURL:sourceURL toURL:dstURL progress:^(NSProgress *progress) {
        NSLog(@"%f", progress.fractionCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView1.progress = progress.fractionCompleted;
        });
        
    } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
        NSLog(@"%lu", fileOperation.writeState);
    }];
    
    [OSFileManager defaultManager].currentOperationsFinishedBlock = ^{
        NSLog(@"当前任务已全部完成");
    };
}
- (IBAction)cancelBigFileCopy:(id)sender {
    if (_bidOperation) {
        [_bidOperation cancel];
    }
    
}
- (IBAction)bigFileCopy:(id)sender {
    
    [self createCopyDstFolder];
    
    NSURL *sourceURL = [NSURL fileURLWithPath:[kDoucmentPath stringByAppendingPathComponent:@"testcopy_bigfile"]];
    NSURL *dstURL = [NSURL fileURLWithPath:kCopyDirectory];
    _bidOperation = [[OSFileManager defaultManager] copyItemAtURL:sourceURL toURL:dstURL progress:^(NSProgress *progress) {
        NSLog(@"%f", progress.fractionCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView2.progress = progress.fractionCompleted;
        });
    } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
        
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [OSFileManager defaultManager].totalProgressBlock = ^(NSProgress *progress) {
      dispatch_async(dispatch_get_main_queue(), ^{
          self.totalProgress.progress = progress.fractionCompleted;
      });
    };
}
- (IBAction)documentBrower:(id)sender {
    
    FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:kDoucmentPath];
    [self.navigationController showViewController:vc sender:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)createCopyDstFolder {
    NSFileManager *fileManager = [NSFileManager new];
    
    BOOL isExist = NO, isDirectory = NO;
    isExist = [fileManager fileExistsAtPath:kCopyDirectory isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [fileManager createDirectoryAtPath:kCopyDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
@end
