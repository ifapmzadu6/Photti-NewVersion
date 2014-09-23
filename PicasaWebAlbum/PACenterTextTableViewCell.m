//
//  PACenterTextTableViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PACenterTextTableViewCell.h"

@interface PACenterTextTableViewCell ()

@end

@implementation PACenterTextTableViewCell

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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _centerTextLabel = [UILabel new];
    _centerTextLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_centerTextLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _centerTextLabel.frame = CGRectMake(15.0f, 0.0f, CGRectGetWidth(rect)-15.0f*2.0f, CGRectGetHeight(rect));
}

@end
