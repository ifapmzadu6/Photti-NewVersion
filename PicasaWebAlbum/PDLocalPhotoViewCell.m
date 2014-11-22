//
//  PDLocalPhotoViewCell.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDLocalPhotoViewCell.h"
#import <PWProgressView.h>

@interface PDLocalPhotoViewCell ()

@property (strong, nonatomic) PWProgressView *progressView;

@end

@implementation PDLocalPhotoViewCell

- (void)initialization {
    [super initialization];
    
    _progressView = [PWProgressView new];
    [self.contentView addSubview:_progressView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _progressView.frame = self.imageView.frame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _progress = 0.0f;
    
    _progressView.progress = 0.0f;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    
    _progressView.progress = progress;
    [_progressView setNeedsLayout];
}

@end
