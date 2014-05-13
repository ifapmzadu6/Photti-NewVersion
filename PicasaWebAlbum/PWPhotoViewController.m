//
//  PWPhotoViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoViewController.h"

#import "PWColors.h"
#import "PWPicasaAPI.h"
#import "SDImageCache.h"
#import "UIImageView+AFNetworking.h"

#import "PWImageScrollView.h"

@interface PWPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;

@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation PWPhotoViewController

- (id)initWithPhoto:(PWPhotoObject *)photo {
    self = [self init];
    if (self) {
        _photo = photo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageScrollView = [[PWImageScrollView alloc] initWithFrame:self.view.bounds];
    _imageScrollView.autoresizesSubviews = YES;
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_imageScrollView];
    
    [self loadImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark LoadImage
- (void)loadImage {
    NSArray *thumbnails = _photo.media.thumbnail.allObjects;
    thumbnails = [thumbnails sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PWPhotoMediaThumbnailObject *thumbnail1 = (PWPhotoMediaThumbnailObject *)obj1;
        PWPhotoMediaThumbnailObject *thumbnail2 = (PWPhotoMediaThumbnailObject *)obj2;
        return MAX(thumbnail1.width.integerValue, thumbnail1.height.integerValue) > MAX(thumbnail2.width.integerValue, thumbnail2.height.integerValue);
    }];
    PWPhotoMediaThumbnailObject *thumbnail = thumbnails.firstObject;
    NSString *urlString = thumbnail.url;
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *memoryCachedImage = [imageCache imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        [_imageScrollView setImage:memoryCachedImage];
        [self loadhighResolutionImage];
    }
    else {
        if ([imageCache diskImageExistsWithKey:urlString]) {
            __weak typeof(self) wself = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage *diskCachedImage = [imageCache imageFromDiskCacheForKey:urlString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself.imageScrollView setImage:diskCachedImage];
                    
                    [sself loadhighResolutionImage];
                });
            });
        }
        else {
            NSURL *url = [NSURL URLWithString:urlString];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            __weak typeof(self) wself = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.description);
                        return;
                    }
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    UIImage *image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typeof(wself) sself = wself;
                        if (!sself) return;
                        
                        [sself.imageScrollView setImage:image];
                        
                        [sself loadhighResolutionImage];
                    });
                    SDImageCache *imageCache = [SDImageCache sharedImageCache];
                    [imageCache storeImage:image forKey:urlString toDisk:YES];
                }] resume];
            });
        }
    }
}

- (void)loadhighResolutionImage {
    NSArray *contents = _photo.media.content.allObjects;
    contents = [contents sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PWPhotoMediaContentObject *content1 = (PWPhotoMediaContentObject *)obj1;
        PWPhotoMediaContentObject *content2 = (PWPhotoMediaContentObject *)obj2;
        return MAX(content1.width.integerValue, content1.height.integerValue) > MAX(content2.width.integerValue, content2.height.integerValue);
    }];
    PWPhotoMediaThumbnailObject *content = contents.firstObject;
    NSString *urlString = content.url;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.imageScrollView setImage:image];
            });
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            [imageCache storeImage:image forKey:urlString toDisk:YES];
        }];
        [task resume];
        sself.task = task;
    }];
}

@end
