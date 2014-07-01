//
//  PWSearchTableViewLocalAlbumCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSearchTableViewLocalAlbumCell.h"

#import "PLModelObject.h"
#import "PLAssetsManager.h"

@interface PWSearchTableViewLocalAlbumCell ()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *thumbnailImageView;

@property (nonatomic) NSUInteger urlHash;

@end

@implementation PWSearchTableViewLocalAlbumCell

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _titleLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_titleLabel];
    
    _thumbnailImageView = [[UIImageView alloc] init];
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailImageView.clipsToBounds = YES;
    [self.contentView addSubview:_thumbnailImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _thumbnailImageView.frame = CGRectMake(15.0f, 4.0f, 36.0f, 36.0f);
    
    _titleLabel.frame = CGRectMake(51.0f + 10.0f, 0.0f, rect.size.width - (51.0f + 10.0f) - 15.0f, rect.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setAlbum:(PLAlbumObject *)album {
    _titleLabel.text = album.name;
    
    _thumbnailImageView.image = nil;
    
    NSUInteger hash = album.hash;
    _urlHash = hash;
    
    PLPhotoObject *thumbnail = album.thumbnail;
    if (!thumbnail) {
        thumbnail = album.photos.firstObject;
    }
    if (thumbnail) {
        NSURL *url = [NSURL URLWithString:thumbnail.url];
        __weak typeof(self) wself = self;
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.urlHash != hash) return;
            
            UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.urlHash != hash) return;
                
                sself.thumbnailImageView.image = image;
            });
        } failureBlock:^(NSError *error) {
            
        }];
    }
}

@end
