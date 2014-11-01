//
//  PWMapViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/10.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import MapKit;

#import "PAMapViewController.h"
#import "PANetworkActivityIndicator.h"

static NSString * const kPWMapViewControllerAppleMapURL = @"http://maps.apple.com";
static NSString * const kPWMapViewControllerGMapURLSheme = @"comgooglemaps://";
static NSString * const kPWMapViewControllerGMapHTTPURL = @"http://maps.google.com/";

@interface PWAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@end
@implementation PWAnnotation
@end



@interface PAMapViewController () <MKMapViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) MKMapView *mapView;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation PAMapViewController

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIImageView *imageView = [UIImageView new];
    imageView.image = _image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.view addSubview:imageView];
    CGPoint center = self.view.center;
    CGFloat startSize = 150.0f;
    CGFloat endSize = 60.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        endSize = 100.0f;
    }
    imageView.frame = CGRectMake(0.0f, 0.0f, startSize, startSize);
    imageView.center = center;
    [UIView animateWithDuration:0.5f animations:^{
        imageView.frame = CGRectMake(0.0f, 0.0f, endSize, endSize);
        imageView.center = center;
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _mapView.frame = self.view.bounds;
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionBarButtonAction:(id)sender {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        NSString *param = [NSString stringWithFormat:@"q=%lf,%lf", _coordinate.latitude, _coordinate.longitude];
        
        UIAlertAction *openInMapsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Maps", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *url = [NSString stringWithFormat:@"%@/?%@", kPWMapViewControllerAppleMapURL, param];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }];
        UIAlertAction *openInGoogleMapsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Google Maps", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *urlScheme = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapURLSheme, param];
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlScheme]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlScheme]];
            }
            else {
                NSString *url = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapHTTPURL, param];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            }
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        alertController.popoverPresentationController.barButtonItem = sender;
        [alertController addAction:openInGoogleMapsAction];
        [alertController addAction:openInMapsAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        UIActionSheet *actionSheet = nil;
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kPWMapViewControllerGMapURLSheme]]) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Maps", nil), NSLocalizedString(@"Open in Google Maps", nil), nil];
        }
        else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Maps", nil), nil];
        }
        
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
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

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    NSString *param = [NSString stringWithFormat:@"q=%lf,%lf", _coordinate.latitude, _coordinate.longitude];
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Open in Maps", nil)]) {
        NSString *url = [NSString stringWithFormat:@"%@/?%@", kPWMapViewControllerAppleMapURL, param];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"Open in Google Maps", nil)]) {
        NSString *urlScheme = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapURLSheme, param];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlScheme]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlScheme]];
        }
        else {
            NSString *url = [NSString stringWithFormat:@"%@?%@", kPWMapViewControllerGMapHTTPURL, param];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    }
}

@end
