
//
//  PLNewAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/14.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNewAlbumEditViewController.h"

#import <BlocksKit+UIKit.h>

@interface PLNewAlbumEditViewController ()

@end

@implementation PLNewAlbumEditViewController

- (id)initWithTitle:(NSString *)title timestamp:(NSNumber *)timestamp uploading_type:(NSNumber *)uploading_type {
    self = [super initWithTitle:title timestamp:timestamp uploading_type:uploading_type];
    if (self) {
        self.title = NSLocalizedString(@"New Album", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    if (self.nameTextField) {
        return self.nameTextField;
    }
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 60.0f, 20.0f)];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.text = self.name;
    textField.placeholder = NSLocalizedString(@"New Album", nil);
    textField.returnKeyType = UIReturnKeyDone;
    [textField setBk_shouldReturnBlock:^BOOL(UITextField *textField) {
        [textField resignFirstResponder];
        
        return YES;
    }];
    textField.exclusiveTouch = YES;
    
    self.nameTextField = textField;
    
    return textField;
}

@end
