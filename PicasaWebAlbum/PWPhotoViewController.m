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
#import "PWImageScrollView.h"

@interface PWPhotoViewController ()

@property (strong, nonatomic) PWImageScrollView *imageScrollView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@property (weak, nonatomic) NSURLSessionDataTask *task;

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
    _imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _imageScrollView.handleSingleTapBlock = _handleSingleTapBlock;
    [self.view addSubview:_imageScrollView];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicatorView.center = self.view.center;
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    [self loadImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_viewDidAppearBlock) {
        _viewDidAppearBlock();
    }
}

- (void)dealloc {    
    NSURLSessionDataTask *task = _task;
    if (task) {
        [task cancel];
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
    NSString *urlString = _photo.tag_thumbnail_url;
    
    UIImage *memoryCache = [_photoViewCache objectForKey:urlString];
    if (memoryCache) {
        [_indicatorView stopAnimating];
        [_imageScrollView setImage:memoryCache];
        
        [self loadScreenResolutionImage];
        
        return;
    }
    
    UIImage *memoryCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:urlString];
    if (memoryCachedImage) {
        [_indicatorView stopAnimating];
        [_imageScrollView setImage:memoryCachedImage];
        
        [self loadScreenResolutionImage];
        
        return;
    }
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:urlString]) {
            UIImage *diskCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlString];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                [sself.indicatorView stopAnimating];
                [sself.imageScrollView setImage:diskCachedImage];
                
                [sself loadScreenResolutionImage];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        
        [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:urlString] completion:^(NSMutableURLRequest *request, NSError *error) {
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
                if (!image) return;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [sself.indicatorView stopAnimating];
                    [sself.imageScrollView setImage:image];
                    
                    [sself loadScreenResolutionImage];
                });
                
                [[SDImageCache sharedImageCache] storeImage:image forKey:urlString toDisk:YES];
            }];
            [task resume];
            
            sself.task = task;
        }];
    });
}

- (void)loadScreenResolutionImage {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *urlString = _photo.tag_screenimage_url;
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof(self) wself = self;
    [PWPicasaAPI getAuthorizedURLRequest:url completion:^(NSMutableURLRequest *request, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
            NSLog(@"%@", error.description);
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                [sself.imageScrollView setImage:image];
            });
            
            [sself.photoViewCache setObject:image forKey:urlString];
        }];
        [task resume];
        sself.task = task;
    }];
}

@end
