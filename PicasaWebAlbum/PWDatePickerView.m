//
//  PWDatePickerView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWDatePickerView.h"

@interface PWDatePickerView ()

@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIView *toolbarBottomLineView;

@end

@implementation PWDatePickerView

- (id)initWithDate:(NSDate *)date {
    self = [super init];
    if (self) {        
        _datePicker.date = date;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [UIColor whiteColor];
    
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.exclusiveTouch = YES;
    [self addSubview:_datePicker];
    
    _toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    _toolbar.items = @[cancelBarButtonItem, flexibleSpace, doneBarButtonItem];
    for (UIView *view in _toolbar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    [self addSubview:_toolbar];
    
    _toolbarBottomLineView = [UIView new];
    _toolbarBottomLineView.backgroundColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
    [self addSubview:_toolbarBottomLineView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _datePicker.frame = CGRectMake(0.0f, 44.0f, rect.size.width, rect.size.height - 44.0f);
    
    _toolbar.frame = CGRectMake(0.0f, 0.0f, rect.size.width, 44.0f);
    
    _toolbarBottomLineView.frame = CGRectMake(0.0f, 44.0f - 0.5f, rect.size.width, 0.5f);
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    __weak typeof(self) wself = self;
    if (_doneBlock) {
        _doneBlock(wself, _datePicker.date);
    }
}

- (void)cancelBarButtonAction {
    __weak typeof(self) wself = self;
    if (_cancelBlock) {
        _cancelBlock(wself);
    }
}

#pragma mark Method
- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    _toolbar.tintColor = tintColor;
}

@end
