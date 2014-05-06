//
//  PWAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumViewCell.h"

#import "PWModelObject.h"
#import "UIImageView+AFNetworking.h"
#import "PWPicasaAPI.h"
#import "PWColors.h"

@interface PWAlbumViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *settingButton;

@end

@implementation PWAlbumViewCell

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
    self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    [self.contentView addSubview:_titleLabel];
    
    _settingButton = [[UIButton alloc] init];
    _settingButton.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0f];
    [self.contentView addSubview:_settingButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.bounds;
    
    _imageView.frame = CGRectMake(0.0f, 0.0f, rect.size.width, ceilf(rect.size.width * 3.0f / 4.0f));
    
    _titleLabel.frame = CGRectMake(8.0f, CGRectGetMaxY(_imageView.frame) + 4.0f, rect.size.width - 16.0f, 14.0f);
    
    _settingButton.frame = CGRectMake(CGRectGetMaxX(rect) - 20.0f, CGRectGetMaxY(_imageView.frame) + 5.0f, 20.0f, 30.0f);
}

- (void)setAlbum:(PWAlbumObject *)album {
    _album = album;
    
    _imageView.image = nil;
    _imageView.alpha = 0.0f;
    for (PWPhotoMediaThumbnailObject *thumbnail in album.media.thumbnail.allObjects) {
        if (thumbnail.width.intValue == 160) {
            NSURL *url = [NSURL URLWithString:thumbnail.url];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            GTMOAuth2Authentication *auth = [PWOAuthManager authentication];
            __weak typeof(self) wself = self;
            [auth authorizeRequest:request completionHandler:^(NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                [sself.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    sself.imageView.image = image;
                    [UIView animateWithDuration:0.2f animations:^{
                        sself.imageView.alpha = 1.0f;
                    }];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.description);
                    }
                }];
            }];
        }
    }
    
    _titleLabel.text = album.title;
    
    [self setNeedsLayout];
}

@end
