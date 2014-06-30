//
//  PWSearchTableViewWebAlbumCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSearchTableViewWebAlbumCell.h"

#import "PWModelObject.h"
#import "PWPicasaAPI.h"
#import "SDImageCache.h"

@interface PWSearchTableViewWebAlbumCell ()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *thumbnailImageView;

@property (nonatomic) NSUInteger albumHash;
@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PWSearchTableViewWebAlbumCell

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

- (void)setAlbum:(PWAlbumObject *)album isNowLoading:(BOOL)isNowLoading {
    _album = album;
    
    _titleLabel.text = album.title;
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    NSString *urlString = album.tag_thumbnail_url;
    if (!urlString) return;
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        _thumbnailImageView.image = memoryCachedImage;
        _thumbnailImageView.alpha = 1.0f;
        
        return;
    }
    
    _thumbnailImageView.alpha = 0.0f;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_albumHash != hash) return;
        
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            if (_albumHash != hash) return;
            
            [self setImage:memoryCachedImage hash:hash];
            
            return;
        }
        
        if ([imageCache diskImageExistsWithKey:urlString]) {
            if (_albumHash != hash) return;
            
            UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
            [self setImage:diskCachedImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *beforeTask = _task;
        if (beforeTask) {
            [beforeTask cancel];
        }
        
        if (isNowLoading) {
            return;
        }
        
        __weak typeof(self) wself = self;
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.albumHash != hash) return;
                
                request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    
                    UIImage *image = [UIImage imageWithData:data];
                    if (sself.albumHash == hash) {
                        [sself setImage:image hash:hash];
                    }
                    
                    SDImageCache *imageCache = [SDImageCache sharedImageCache];
                    [imageCache storeImage:image forKey:urlString toDisk:YES];
                }];
                [task resume];
                
                sself.task = task;
            });
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (_albumHash != hash) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_albumHash != hash) {
            return;
        }
        
        _thumbnailImageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _thumbnailImageView.alpha = 1.0f;
        }];
    });
}

@end
