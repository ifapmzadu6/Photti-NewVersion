//
//  PHVideoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHVideoViewCell.h"

#import "PAIcons.h"

@interface PHVideoViewCell ()

@end

@implementation PHVideoViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _imageView = [UIImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
    
    _videoIconImageView = [UIImageView new];
    _videoIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _videoIconImageView.clipsToBounds = YES;
    _videoIconImageView.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
    _videoIconImageView.image = [PAIcons videoButtonIconWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:100.0f];
    [self.contentView addSubview:_videoIconImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _imageView.frame = rect;
    _videoIconImageView.center = self.contentView.center;
}

@end
