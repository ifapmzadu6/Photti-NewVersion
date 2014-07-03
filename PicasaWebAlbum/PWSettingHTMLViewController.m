//
//  SettingHTMLViewController.m
//  CommeTube
//
//  Created by Keisuke Karijuku on 2013/11/26.
//  Copyright (c) 2013年 IRIE JUNYA. All rights reserved.
//

#import "PWSettingHTMLViewController.h"

@interface PWSettingHTMLViewController ()

@property (strong, nonatomic) UIWebView *webView;

@end

@implementation PWSettingHTMLViewController

- (void)loadView {
    _webView = [[UIWebView alloc] init];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _webView.scalesPageToFit = true;
    _webView.exclusiveTouch = YES;
    self.view = _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:_fileName ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    [_webView loadHTMLString:html baseURL:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
