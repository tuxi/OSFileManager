//
//  SampleIOSViewController.m
//  OSFileManager_iOS_Sample
//
//  Created by Ossey on 2017/7/23.
//  Copyright © 2017年 Ossey. All rights reserved.
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

@end

@implementation SampleIOSViewController

+ (void)load {
    NSFileManager *fileManager = [NSFileManager new];
    
    BOOL isExist = NO, isDirectory = NO;
    isExist = [fileManager fileExistsAtPath:kCopyDirectory isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [fileManager createDirectoryAtPath:kCopyDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
}


- (IBAction)samllFileCopy:(id)sender {
    
    NSURL *sourceURL = [NSURL fileURLWithPath:[kDoucmentPath stringByAppendingPathComponent:@"testcopy"]];
    NSURL *dstURL = [NSURL fileURLWithPath:kCopyDirectory];
    [[OSFileManager defaultManager] copyItemAtURL:sourceURL toURL:dstURL progress:^(NSProgress *progress) {
        NSLog(@"%f", progress.fractionCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView1.progress = progress.fractionCompleted;
        });
        
    } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
        NSLog(@"%ld", fileOperation.writeState);
    }];
}
- (IBAction)bigFileCopy:(id)sender {
    
    NSURL *sourceURL = [NSURL fileURLWithPath:[kDoucmentPath stringByAppendingPathComponent:@"testcopy_bigfile"]];
    NSURL *dstURL = [NSURL fileURLWithPath:kCopyDirectory];
    [[OSFileManager defaultManager] copyItemAtURL:sourceURL toURL:dstURL progress:^(NSProgress *progress) {
        NSLog(@"%f", progress.fractionCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView2.progress = progress.fractionCompleted;
        });
    } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
        NSLog(@"%ld", fileOperation.writeState);
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
    
    FoldersViewController *vc = [[FoldersViewController alloc] initWithPath:kDoucmentPath];
    [self.navigationController showViewController:vc sender:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
