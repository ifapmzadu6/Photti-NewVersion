//
//  PWCollectionFooterView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLCollectionFooterView.h"

#import "PAColors.h"

@interface PLCollectionFooterView ()

@property (strong, nonatomic) UILabel *textLabel;

@end

@implementation PLCollectionFooterView

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
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
    _textLabel = [UILabel new];
    _textLabel.font = [UIFont systemFontOfSize:14.0f];
    _textLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.adjustsFontSizeToFitWidth = YES;
    _textLabel.minimumScaleFactor = 0.5f;
    [self addSubview:_textLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _textLabel.frame = CGRectMake(12.0f, 0.0f, CGRectGetWidth(rect) - 24.0f, 50.0f);
}

- (void)setText:(NSString *)text {
    _textLabel.text = text;
}

@end
