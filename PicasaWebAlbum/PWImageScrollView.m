//
//  PWImageScrollView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWImageScrollView.h"

@interface PWImageScrollView ()

@property (strong, nonatomic) UIImageView *imageView;

@property (nonatomic) CGPoint pointToCenterAfterResize;
@property (nonatomic) CGFloat scaleToRestoreAfterResize;
@property (nonatomic) CGSize imageSize;
@property (nonatomic) BOOL isZoom;

@end

@implementation PWImageScrollView

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
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.exclusiveTouch = YES;
    self.zoomScale = 1.0f;
    
//    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    singleTapGesture.numberOfTapsRequired = 1;
//    [self addGestureRecognizer:singleTapGesture];
//    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
//    doubleTapGesture.numberOfTapsRequired = 2;
//    [self addGestureRecognizer:doubleTapGesture];
}

- (void)layoutSubviews  {
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
	   
    _imageView.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
	BOOL myself = !CGSizeEqualToSize(_imageSize, CGSizeZero);
    
	_isZoom = YES;
	
    if (sizeChanging && myself) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging && myself) {
        [self recoverFromResizing];
    }
    
	_isZoom = NO;
}

- (void)setImage:(UIImage *)image {
    if (_imageView) {
        _imageView.image = image;
        return;
    }
    
	CGSize dimensions = image.size;
	CGFloat imageWidth = dimensions.width;
	CGFloat imageHeight = dimensions.height;
	if (self.bounds.size.width > self.bounds.size.height) {
		imageHeight = ceilf(imageHeight * self.bounds.size.width / imageWidth);
		imageWidth = ceilf(self.bounds.size.width);
	}
	else {
		imageWidth = ceilf(imageWidth * self.bounds.size.height / imageHeight);
		imageHeight = ceilf(self.bounds.size.height);
	}
	_imageSize = CGSizeMake(imageWidth, imageHeight);
	
	_imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, imageWidth, imageHeight)];
	_imageView.contentMode = UIViewContentModeScaleAspectFill;
	_imageView.image = image;
	[self addSubview:_imageView];
	
	self.contentSize = _imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
	
	_isZoom = NO;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return  _imageView;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    CGSize boundsSize = self.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;
    CGFloat yScale = boundsSize.height / _imageSize.height;
	
	CGFloat minScale = MIN(xScale, yScale);
	
    self.minimumZoomScale = minScale;
    self.maximumZoomScale = minScale * 9.0f;
}

#pragma mark -
#pragma mark Methods called during rotation to preserve the zoomScale and the visible portion of the image

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
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
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

@end
