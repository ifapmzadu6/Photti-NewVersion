//
//  PDUploadBarButtonItem.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDUploadBarButtonItem.h"

@interface PDUploadBarButtonItem ()

@end

@implementation PDUploadBarButtonItem

- (instancetype)init {
    self = [super init];
    if (self) {
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
        [button setImage:[UIImage imageNamed:@"Upload"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonTouchCancel:) forControlEvents:UIControlEventTouchCancel];
        [button addTarget:self action:@selector(buttonTouchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
        [button addTarget:self action:@selector(buttonTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
        [button addTarget:self action:@selector(buttonTouchDragInside:) forControlEvents:UIControlEventTouchDragInside];
        [button addTarget:self action:@selector(buttonTouchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
        [button addTarget:self action:@selector(buttonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(buttonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        self.customView = button;
    }
    return self;
}

- (void)setNormalImage {
    UIButton *button = (UIButton *)self.customView;
    [button setImage:[UIImage imageNamed:@"Upload"] forState:UIControlStateNormal];
}

- (void)startAnimation {
    if (_animated) {
        return;
    }
    _animated = YES;
    
    [self animateLeftNavigationButtonWithIndex:0];
}

- (void)endAnimation {
    _animated = NO;
}

- (void)animateLeftNavigationButtonWithIndex:(NSUInteger)index {
    CGFloat interval = 0.2f;
    NSUInteger nextIndex = (index + 1) % 4;
    NSString *imageName = [@"UploadAnimation" stringByAppendingFormat:@"%ld", (long)nextIndex];
    UIImage *image = [UIImage imageNamed:imageName];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_animated && nextIndex == 0) {
            [self setNormalImage];
            return;
        }
        
        UIButton *button = (UIButton *)self.customView;
        [button setImage:image forState:UIControlStateNormal];
        
        [self animateLeftNavigationButtonWithIndex:nextIndex];
    });
}



#pragma mark UIButton Touch
- (void)buttonTouchDown:(UIButton *)sender {
    sender.alpha = 0.2f;
}

- (void)buttonTouchCancel:(UIButton *)sender {
    sender.alpha = 1.0f;
}

- (void)buttonTouchDragEnter:(UIButton *)sender {
    sender.alpha = 0.2f;
}

- (void)buttonTouchDragExit:(UIButton *)sender {
    sender.alpha = 1.0f;
}

- (void)buttonTouchDragInside:(UIButton *)sender {
    sender.alpha = 0.2f;
}

- (void)buttonTouchDragOutside:(UIButton *)sender {
    sender.alpha = 1.0f;
}

- (void)buttonTouchUpInside:(UIButton *)sender {
    sender.alpha = 1.0f;
}

- (void)buttonTouchUpOutside:(UIButton *)sender {
    sender.alpha = 1.0f;
}

@end
