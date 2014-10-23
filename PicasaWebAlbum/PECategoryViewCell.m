//
//  PALeftCollectionViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PECategoryViewCell.h"

#import "PAColors.h"
#import "PAHorizontalScrollView.h"
#import "PEAlbumViewCell.h"
#import "PEMomentViewCell.h"
#import "PALinkableTextView.h"

@interface PECategoryViewCell () <UITextViewDelegate>

@property (strong, nonatomic) UIImageView *greaterThanImageView;

@end

@implementation PECategoryViewCell

static NSString * const kPECategoryViewCellSettingsKey = @"kPECategoryViewCellSettingsKey";

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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:16.0f];
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _moreButton = [UIButton new];
    [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [_moreButton setTitle:NSLocalizedString(@"See All", nil) forState:UIControlStateNormal];
    [_moreButton setTitleColor:[PAColors getColor:PAColorsTypeTextLightSubColor] forState:UIControlStateNormal];
    _moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _moreButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 10.0f);
    [self.contentView addSubview:_moreButton];
    
    _greaterThanImageView = [UIImageView new];
    _greaterThanImageView.image = [[UIImage imageNamed:@"GreaterThan"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _greaterThanImageView.tintColor = [PAColors getColor:PAColorsTypeTextLightSubColor];
    _greaterThanImageView.frame = CGRectMake(0.0f, 0.0f, 8.0f, 10.0f);
    [self.contentView addSubview:_greaterThanImageView];
    
    _horizontalScrollView = [PAHorizontalScrollView new];
    _horizontalScrollView.collectionView.contentInset = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 15.0f);
    [self.contentView addSubview:_horizontalScrollView];
    
    _noItemLabel = [PALinkableTextView new];
    NSString *hideOnSettingsString = NSLocalizedString(@"You can hide this category on Settings.", nil);
    NSMutableAttributedString *hideOnSettingsAttributedString = [[NSMutableAttributedString alloc] initWithString:hideOnSettingsString];
    NSRange settingsRange = [hideOnSettingsString rangeOfString:NSLocalizedString(@"Settings", nil)];
    [hideOnSettingsAttributedString addAttribute:NSLinkAttributeName value:kPECategoryViewCellSettingsKey range:settingsRange];
    NSMutableAttributedString *noItemAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"No Items", nil)];
    NSAttributedString *enterCodeAttributedString = [[NSAttributedString alloc] initWithString:@"\n"];
    [noItemAttributedString appendAttributedString:enterCodeAttributedString];
    [noItemAttributedString appendAttributedString:hideOnSettingsAttributedString];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    [noItemAttributedString addAttributes:@{NSParagraphStyleAttributeName: style, NSFontAttributeName: [UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName: [PAColors getColor:PAColorsTypeTextColor]} range:NSMakeRange(0, noItemAttributedString.length)];
    _noItemLabel.attributedText = noItemAttributedString;
    _noItemLabel.linkTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:PAColorsTypeTintLocalColor]};
    _noItemLabel.delegate = self;
    _noItemLabel.editable = NO;
    _noItemLabel.scrollEnabled = NO;
    [self.contentView addSubview:_noItemLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _titleLabel.frame = CGRectMake(15.0f, 20.0f, 200.0f, 20.0f);
    [_moreButton sizeToFit];
    CGFloat moreButtonWidth = CGRectGetWidth(_moreButton.bounds) + 50.0f;
    _moreButton.frame = CGRectMake(CGRectGetWidth(rect) - moreButtonWidth - 15.0f, 17.0f, moreButtonWidth, 26.0f);
    _greaterThanImageView.frame = CGRectMake(CGRectGetMaxX(_moreButton.frame)-CGRectGetWidth(_greaterThanImageView.frame), CGRectGetMinY(_moreButton.frame)+(CGRectGetHeight(_moreButton.frame)-CGRectGetHeight(_greaterThanImageView.frame))/2.0f, CGRectGetWidth(_greaterThanImageView.frame), CGRectGetHeight(_greaterThanImageView.frame));
    _horizontalScrollView.frame = CGRectMake(0.0f, 38.0f, CGRectGetWidth(rect), CGRectGetHeight(rect) - 38.0f);
    [_noItemLabel sizeToFit];
    _noItemLabel.center = _horizontalScrollView.center;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.tag = NSIntegerMax;
    
    UIEdgeInsets contentInsets = _horizontalScrollView.collectionView.contentInset;
    _horizontalScrollView.collectionView.contentOffset = CGPointMake(-contentInsets.left, 0.0f);
    
    _horizontalScrollView.delegate = nil;
    _horizontalScrollView.dataSource = nil;
}

- (void)moreButtonAction {
    if (_moreButtonActionBlock) {
        _moreButtonActionBlock();
    }
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (_didSelectSettingsBlock) {
        _didSelectSettingsBlock();
    }
    return NO;
};

@end
