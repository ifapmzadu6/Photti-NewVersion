//
//  PWImageScrollView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAImageScrollView.h"

@interface PAImageScrollView () <UIScrollViewDelegate>

@property (nonatomic) CGPoint pointToCenterAfterResize;
@property (nonatomic) CGFloat scaleToRestoreAfterResize;
@property (nonatomic) CGSize imageSize;

@end

@implementation PAImageScrollView

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
    self.exclusiveTouch = YES;
    self.zoomScale = 1.0f;
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGesture];
    
    _imageViewClass = UIImageView.class;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    [_imageView removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)centerScrollViewContentsWithView:(UIView *)view {
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = view.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0f;
    else
        frameToCenter.origin.x = 0.0f;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0f;
    else
        frameToCenter.origin.y = 0.0f;
    
    view.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.bounds.size);
	BOOL notSizeZero = !CGSizeEqualToSize(_imageSize, CGSizeZero);
    
    if (sizeChanging && notSizeZero) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging && notSizeZero) {
        [self recoverFromResizing];
    }
}

#pragma mark Methods
- (void)setImage:(UIImage *)image {
    if (_imageView) {
        _imageView.image = image;
        return;
    }
    if (!image) {
        return;
    }
    
	CGFloat imageWidth = image.size.width;
	CGFloat imageHeight = image.size.height;
	if (CGRectGetWidth(self.bounds) > CGRectGetHeight(self.bounds)) {
		imageHeight = imageHeight * CGRectGetWidth(self.bounds) / imageWidth;
		imageWidth = CGRectGetWidth(self.bounds);
	}
	else {
		imageWidth = imageWidth * CGRectGetHeight(self.bounds) / imageHeight;
		imageHeight = CGRectGetHeight(self.bounds);
	}
	_imageSize = CGSizeMake(imageWidth, imageHeight);
	
    _imageView = [[_imageViewClass alloc] initWithFrame:(CGRect){CGPointZero, _imageSize}];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
	_imageView.image = image;
	[self addSubview:_imageView];
	
	self.contentSize = _imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
    
    [self centerScrollViewContentsWithView:_imageView];
}

- (UIImage *)image {
    return _imageView.image;
}

- (void)setIsDisableZoom:(BOOL)isDisableZoom {
    _isDisableZoom = isDisableZoom;
    
    if (isDisableZoom) {
        self.maximumZoomScale = self.minimumZoomScale;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (_handleFirstZoomBlock && (self.zoomScale > self.minimumZoomScale)) {
        _handleFirstZoomBlock();
        _handleFirstZoomBlock = nil;
    }
    
    [self centerScrollViewContentsWithView:_imageView];
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    CGSize boundsSize = self.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;
    CGFloat yScale = boundsSize.height / _imageSize.height;
	CGFloat minScale = MIN(xScale, yScale);
	
    self.minimumZoomScale = minScale;
    self.maximumZoomScale = minScale * 9.0f;
    
    if (_isDisableZoom) {
        self.maximumZoomScale = self.minimumZoomScale;
    }
}

#pragma mark - Rotation support

- (void)prepareToResize {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:_imageView];
	
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing {
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
	
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:_imageView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0f,
                                 boundsCenter.y - self.bounds.size.height / 2.0f);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

#pragma mark Gesture
- (void)handleSingleTap:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded){
		[self performSelector:@selector(singleTap) withObject:nil afterDelay:0.4f];
	}
}

- (void)singleTap {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (_handleSingleTapBlock) {
        _handleSingleTapBlock();
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
    if (_isDisableZoom) {
        return;
    }
    
	if (sender.state == UIGestureRecognizerStateEnded){
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [UIView animateWithDuration:0.4f animations:^{
            if (self.zoomScale == self.minimumZoomScale * 3.0f) {
                CGPoint center = [sender locationInView:_imageView];
                CGFloat scale = self.maximumZoomScale;
                CGRect zoomRect = [self zoomRectForScrollView:self
                                                    withScale:scale
                                                   withCenter:center];
                [self zoomToRect:zoomRect animated:NO];
            }
            else if (self.zoomScale > self.minimumZoomScale) {
                [self setZoomScale:self.minimumZoomScale animated:NO];
            } else {
                CGPoint center = [sender locationInView:_imageView];
                CGFloat scale = self.minimumZoomScale * 3.0f;
                CGRect zoomRect = [self zoomRectForScrollView:self
                                                    withScale:scale
                                                   withCenter:center];
                [self zoomToRect:zoomRect animated:NO];
            }
            [self setNeedsLayout];
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
        }];
	}
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width  = scrollView.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0f);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0f);
    return zoomRect;
}

@end
