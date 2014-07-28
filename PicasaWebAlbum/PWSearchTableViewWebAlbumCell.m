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

@property (strong, nonatomic) UIImageView *thumbnailImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *albumTypeLabel;

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
    
    _thumbnailImageView = [UIImageView new];
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailImageView.clipsToBounds = YES;
    [self.contentView addSubview:_thumbnailImageView];
    
    _albumTypeLabel = [UILabel new];
    _albumTypeLabel.text = [NSString stringWithFormat:@"- %@", NSLocalizedString(@"Web Album", nil)];
    _albumTypeLabel.font = [UIFont systemFontOfSize:15.0f];
    _albumTypeLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.333f];
    _albumTypeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_albumTypeLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    _thumbnailImageView.frame = CGRectMake(15.0f, 4.0f, 36.0f, 36.0f);
    
    _titleLabel.frame = CGRectMake(51.0f + 10.0f, 0.0f, rect.size.width - (51.0f + 10.0f) - 15.0f, rect.size.height);
    
    if (!_isShowAlbumType) {
        _albumTypeLabel.frame = CGRectZero;
        
        _titleLabel.frame = CGRectMake(51.0f + 10.0f, 0.0f, rect.size.width - (51.0f + 10.0f) - 15.0f, rect.size.height);
    }
    else {
        CGSize albumTypeLabelSize = [_albumTypeLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        _albumTypeLabel.frame = CGRectMake((rect.size.width - 15.0f) - albumTypeLabelSize.width, 0.0f, albumTypeLabelSize.width, rect.size.height);
        
        _titleLabel.frame = CGRectMake(51.0f + 10.0f, 0.0f, CGRectGetMinX(_albumTypeLabel.frame) - 5.0f, rect.size.height);
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setAlbum:(PWAlbumObject *)album searchedText:(NSString *)searchedText {
    _album = album;
    
    NSString *text = album.title;
    NSMutableAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text].mutableCopy;
    if (searchedText) {
        NSRange searchRange = NSMakeRange(0, [text length]);
        NSRange place = NSMakeRange(0, 0);
        while (searchRange.location < [text length]) {
            place = [text rangeOfString:searchedText options:NSLiteralSearch range:searchRange];
            if (place.location != NSNotFound) {
                [attributedText addAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f]} range:place];
            }
            searchRange.location = place.location + place.length;
            searchRange.length = [text length] - searchRange.location;
        }
    }
    _titleLabel.attributedText = attributedText;
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    NSString *urlString = album.tag_thumbnail_url;
    if (!urlString) return;
    
    UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        _thumbnailImageView.image = memoryCachedImage;
        _thumbnailImageView.alpha = 1.0f;
        
        return;
    }
    
    _thumbnailImageView.alpha = 0.0f;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_albumHash != hash) return;
        
        UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
        if (memoryCachedImage) {
            [self setImage:memoryCachedImage hash:hash];
            
            return;
        }
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            [self setImage:diskCachedImage hash:hash];
            
            return;
        }
        
        NSURLSessionDataTask *beforeTask = _task;
        if (beforeTask) [beforeTask cancel];
        
        __weak typeof(self) wself = self;
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.albumHash != hash) return;
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (error) {
                    NSLog(@"%@", error.description);
                    return;
                }
                
                UIImage *image = [UIImage imageWithData:data];
                [sself setImage:image hash:hash];
                
                if (image && urlString) {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
                }
            }];
            [task resume];
            
            sself.task = task;
        }];
    });
}

- (void)setImage:(UIImage *)image hash:(NSUInteger)hash {
    if (!image) return;
    if (_albumHash != hash) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_albumHash != hash) return;
        
        _thumbnailImageView.image = image;
        [UIView animateWithDuration:0.1f animations:^{
            _thumbnailImageView.alpha = 1.0f;
        }];
    });
}

@end
