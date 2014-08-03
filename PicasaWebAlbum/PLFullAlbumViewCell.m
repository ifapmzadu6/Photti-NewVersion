//
//  PLFullAlbumViewCell.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/02.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLFullAlbumViewCell.h"

#import "PWColors.h"
#import "PWString.h"
#import "PLModelObject.h"
#import "PLAssetsManager.h"

@interface PLFullAlbumViewCell () <UITextFieldDelegate>

@property (strong, nonatomic) UITextField *titleTextField;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *backImageView;
@property (strong, nonatomic) UIImageView *backImageView2;
@property (strong, nonatomic) UILabel *numberLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) NSUInteger albumHash;

@end

@implementation PLFullAlbumViewCell

- (id)init {
    self = [super init];
    if (self) {
        [self initializetion];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializetion];
    }
    return self;
}

- (void)initializetion {
    self.clipsToBounds = NO;
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    
    _backImageView = [UIImageView new];
    _backImageView.clipsToBounds = YES;
    _backImageView.contentMode = UIViewContentModeScaleAspectFill;
    _backImageView.alpha = 0.667f;
    [self.contentView insertSubview:_backImageView belowSubview:_imageView];
    
    _backImageView2 = [UIImageView new];
    _backImageView2.clipsToBounds = YES;
    _backImageView2.contentMode = UIViewContentModeScaleAspectFill;
    _backImageView2.alpha = 0.333f;
    [self.contentView insertSubview:_backImageView2 belowSubview:_backImageView];
    
    _titleTextField = [UITextField new];
    _titleTextField.font = [UIFont systemFontOfSize:16.0f];
    _titleTextField.textColor = [PWColors getColor:PWColorsTypeTextColor];
    _titleTextField.textAlignment = NSTextAlignmentCenter;
    _titleTextField.returnKeyType = UIReturnKeyDone;
    _titleTextField.delegate = self;
    [self.contentView addSubview:_titleTextField];
    
    _numberLabel = [UILabel new];
    _numberLabel.font = [UIFont systemFontOfSize:13.0f];
    _numberLabel.textColor = [PWColors getColor:PWColorsTypeTextDarkColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_numberLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    
    _titleTextField.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(rect), 30.0f);
    
    _imageView.frame = CGRectMake(0.0f, 50.0f, CGRectGetWidth(rect), CGRectGetWidth(rect)*3.0f/4.0f);
    
    CGFloat dxdy = 5.0f;
    _backImageView.frame = CGRectOffset(_imageView.frame, dxdy, -dxdy);
    _backImageView2.frame = CGRectOffset(_backImageView.frame, dxdy, -dxdy);
    
    _numberLabel.frame = CGRectMake(0.0f, CGRectGetMaxY(_imageView.frame) + 16.0f, CGRectGetWidth(rect), 20.0f);
    
    _activityIndicatorView.center = _imageView.center;
}

- (void)setAlbum:(PLAlbumObject *)album {
    _album = album;
    
    _titleTextField.text = _album.name;
    
    NSOrderedSet *photos = [_album.photos filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypePhoto]];
    NSOrderedSet *videos = [_album.photos filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", ALAssetTypeVideo]];
    _numberLabel.text = [PWString photoAndVideoStringWithPhotoCount:photos.count videoCount:videos.count isInitialUpperCase:YES];
    
    _imageView.image = nil;
    _backImageView.image = nil;
    _backImageView2.image = nil;
    [_activityIndicatorView startAnimating];
    
    if (!album || !album.managedObjectContext) {
        _albumHash = 0;
        return;
    }
    
    NSUInteger hash = album.hash;
    _albumHash = hash;
    
    NSUInteger count = album.photos.count;
    if (count > 0) {
        [album.photos enumerateObjectsUsingBlock:^(PLPhotoObject *photo, NSUInteger idx, BOOL *stop) {
            if (idx == 3) {
                *stop = YES;
                return;
            }
            
            if (idx == 0) {
                [self loadImageWithAssetURL:photo.url hash:hash imageView:_imageView];
            }
            else if (idx == 1) {
                [self loadImageWithAssetURL:photo.url hash:hash imageView:_backImageView];
            }
            else if (idx == 2) {
                [self loadImageWithAssetURL:photo.url hash:hash imageView:_backImageView2];
            }
        }];
    }
    else {
        [_activityIndicatorView stopAnimating];
    }
}

- (void)loadImageWithAssetURL:(NSString *)urlString hash:(NSUInteger)hash imageView:(UIImageView *)imageView {
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PLAssetsManager sharedLibrary] assetForURL:url resultBlock:^(ALAsset *asset) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.albumHash != hash) return;
            
            UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.albumHash != hash) return;
                
                [sself.activityIndicatorView stopAnimating];
                imageView.image = image;
            });
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                [sself.activityIndicatorView stopAnimating];
            });
        }];
    });
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (_textFieldDidEndEditing) {
        _textFieldDidEndEditing(textField.text);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
