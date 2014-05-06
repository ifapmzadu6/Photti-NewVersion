//
//  PWPhotoViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewCell.h"

#import "PWModelObject.h"
#import "UIImageView+AFNetworking.h"
#import "PWPicasaAPI.h"
#import "PWColors.h"

@interface PWPhotoViewCell ()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation PWPhotoViewCell

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

- (void)initialization {
    self.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundColor];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.bounds;
    
    _imageView.frame = rect;
}

- (void)setPhoto:(PWPhotoObject *)photo {
    _photo = photo;
    
    _imageView.image = nil;
    _imageView.alpha = 0.0f;
    NSURL *url = [NSURL URLWithString:photo.content_src];
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

@end
