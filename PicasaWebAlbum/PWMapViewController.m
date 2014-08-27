//
//  PWMapViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/10.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import MapKit;

#import "PWMapViewController.h"
#import "PANetworkActivityIndicator.h"
#import <BlocksKit+UIKit.h>

static NSString * const kPWMapViewControllerAppleMapURL = @"http://maps.apple.com";
static NSString * const kPWMapViewControllerGMapURLSheme = @"comgooglemaps://";
static NSString * const kPWMapViewControllerGMapHTTPURL = @"http://maps.google.com/";

@interface PWAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@end
@implementation PWAnnotation
@end



@interface PWMapViewController () <MKMapViewDelegate>

@property (strong, nonatomic) MKMapView *mapView;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation PWMapViewController

- (id)initWithImage:(UIImage *)image latitude:(double)latitude longitude:(double)longitude {
    self = [super init];
    if (self) {
        _image = image;
        
        _coordinate.latitude = latitude;
        _coordinate.longitude = longitude;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonAction:)];
    self.navigationItem.leftBarButtonItem = actionBarButtonItem;
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _mapView = [MKMapView new];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    PWAnnotation *annotation = [PWAnnotation new];
    annotation.coordinate = _coordinate;
    [_mapView addAnnotation:annotation];
    
    MKCoordinateRegion region;
    region.center = _coordinate;
    region.span.latitudeDelta = 0.0;
    region.span.longitudeDelta = 0.0;
    [_mapView setRegion:region animated:NO];
    
    NSString *standard = NSLocalizedString(@"Standard", nil);
    NSString *hybrid = NSLocalizedString(@"Hybrid", nil);
    NSString *satelite = NSLocalizedString(@"Satelite", nil);
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[standard, hybrid, satelite]];
    [segmentedControl addTarget:self action:@selector(segmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = segmentedControl;
    
    UIImageView *imageView = [UIImageView new];
    imageView.image = _image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.view addSubview:imageView];
    CGPoint center = self.view.center;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        CGFloat x = center.x;
        center.x = center.y;
        center.y = x;
    }
    CGFloat startSize = 150.0f;
    CGFloat endSize = 60.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        endSize = 100.0f;
    }
    imageView.frame = CGRectMake(center.x - startSize/2.0f, center.y - startSize/2.0f, startSize, startSize);
    [UIView animateWithDuration:0.5f animations:^{
        imageView.frame = CGRectMake(center.x - endSize/2.0f, center.y - endSize/2.0f, endSize, endSize);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _mapView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionBarButtonAction:(id)sender {
    NSString *param = [NSString stringWithFormat:@"q=%lf,%lf", _coordinate.latitude, _coordinate.longitude];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:nil];
    [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Open in Maps", nil) handler:^{
        NSString *url = [NSString stringWithFormat:@"%@/?%@", kPWMapViewControllerAppleMapURL, param];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kPWMapViewControllerGMapURLSheme]]) {
        [actionSheet bk_addButtonWithTitle:NSLocalizedString(@"Open in Google Maps", nil) handler:^{
            NSString *urlScheme = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapURLSheme, param];
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlScheme]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlScheme]];
            }
            else {
                NSString *url = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapHTTPURL, param];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            }
        }];
    }
    [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
    [actionSheet showInView:self.view];
}

#pragma mark UISegmentedControl
- (void)segmentedControlAction:(UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            _mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            _mapView.mapType = MKMapTypeHybrid;
            break;
        case 2:
            _mapView.mapType = MKMapTypeSatellite;
            break;
        default:
            break;
    }
}

#pragma mark MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if (!_image) return nil;

	MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"identifier"];
	if (!annotationView) {
		annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"identifier"];
	}
	annotationView.annotation = annotation;
    annotationView.image = _image;
    annotationView.clipsToBounds = YES;
    annotationView.contentMode = UIViewContentModeScaleAspectFill;
    CGFloat size = 60.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        size = 100.0f;
    }
    annotationView.frame = CGRectMake(-size/2.0f, -size/2.0f, size, size);
    
	return annotationView;
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
	[PANetworkActivityIndicator increment];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
	[PANetworkActivityIndicator decrement];
}

@end
