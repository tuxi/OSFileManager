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
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation SampleIOSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSFileManager *fileManager = [NSFileManager new];
    
    BOOL isExist = NO, isDirectory = NO;
    isExist = [fileManager fileExistsAtPath:kCopyDirectory isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [fileManager createDirectoryAtPath:kCopyDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
}
- (IBAction)documentBrower:(id)sender {
    
    FoldersViewController *vc = [[FoldersViewController alloc] initWithPath:kDoucmentPath];
    [self.navigationController showViewController:vc sender:self];
}

- (IBAction)copyBtnClick:(id)sender {
    
    NSURL *sourceURL = [NSURL fileURLWithPath:[kDoucmentPath stringByAppendingPathComponent:@"testcopy"]];
    NSURL *dstURL = [NSURL fileURLWithPath:kCopyDirectory];
    [[OSFileManager defaultManager] copyItemAtURL:sourceURL toURL:dstURL progress:^(NSProgress *progress) {
        NSLog(@"%f", progress.fractionCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress.fractionCompleted;
        });
        
    } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
        NSLog(@"%ld", fileOperation.writeState);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
