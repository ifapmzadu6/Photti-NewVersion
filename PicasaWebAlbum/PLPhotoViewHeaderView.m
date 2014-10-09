//
//  PLPhotoViewHeaderView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoViewHeaderView.h"

#import "PAColors.h"
#import "UIButton+HitEdgeInsets.h"

@interface PLPhotoViewHeaderView ()

@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) UIButton *selectButton;

@property (nonatomic) BOOL isDeselectButton;

@end

@implementation PLPhotoViewHeaderView

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
    self.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    
    _textLabel = [UILabel new];
    _textLabel.font = [UIFont systemFontOfSize:14.0f];
    _textLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self addSubview:_textLabel];
    
    _detailLabel = [UILabel new];
    _detailLabel.font = [UIFont systemFontOfSize:12.0f];
    _detailLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    [self addSubview:_detailLabel];
    
    _selectButton = [UIButton new];
    [_selectButton addTarget:self action:@selector(selectButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_selectButton setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
    [_selectButton setTitleColor:[PAColors getColor:PAColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_selectButton setTitleColor:[[PAColors getColor:PAColorsTypeTintLocalColor] colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
    _selectButton.hitEdgeInsets = UIEdgeInsetsMake(0.0f, -30.0f, 0.0f, 0.0f);
    _selectButton.exclusiveTouch = YES;
    [self addSubview:_selectButton];
    
    _isDeselectButton = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    
    CGSize textLabelSize = [_textLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _textLabel.frame = CGRectMake(12.0f, 21.0f, textLabelSize.width, 15.0f);
    
    CGSize detailLabelSize = [_detailLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _detailLabel.frame = CGRectMake(12.0f, 38.0f, detailLabelSize.width, 13.0f);
    
    CGSize selectButtonSize = [_selectButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _selectButton.frame = CGRectMake(size.width - selectButtonSize.width - 12.0f, 19.0f, selectButtonSize.width, size.height - 19.0f - 11.0f);
}

- (void)setText:(NSString *)text {
    _textLabel.text = text;
    [self setNeedsLayout];
}

- (void)setDetail:(NSString *)detail {
    _detailLabel.text = detail;
    [self setNeedsLayout];
}

- (void)setSelectButtonIsDeselect:(BOOL)isDeselect {
    if (isDeselect) {
        [_selectButton setTitle:NSLocalizedString(@"Deselect", nil) forState:UIControlStateNormal];
        _isDeselectButton = YES;
    }
    else {
        [_selectButton setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
        _isDeselectButton = NO;
    }
    
    CGSize size = self.bounds.size;
    CGSize selectButtonSize = [_selectButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _selectButton.frame = CGRectMake(size.width - selectButtonSize.width - 12.0f, 17.0f, selectButtonSize.width, size.height - 17.0f - 11.0f);
}

- (void)selectButtonAction {
    if (_isDeselectButton) {
        if (_deselectButtonActionBlock) {
            _deselectButtonActionBlock();
        }
        
        [_selectButton setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
        _isDeselectButton = NO;
    }
    else {
        if (_selectButtonActionBlock) {
            _selectButtonActionBlock();
        }
        
        [_selectButton setTitle:NSLocalizedString(@"Deselect", nil) forState:UIControlStateNormal];
        _isDeselectButton = YES;
    }
    
    CGSize size = self.bounds.size;
    CGSize selectButtonSize = [_selectButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _selectButton.frame = CGRectMake(size.width - selectButtonSize.width - 12.0f, 17.0f, selectButtonSize.width, size.height - 17.0f - 11.0f);
}


@end
