//
//  PWPhotoEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/10.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWPhotoEditViewController.h"

#import "PWColors.h"
#import "PWPicasaAPI.h"
#import "SDImageCache.h"
#import "UIView+ScreenCapture.h"
#import "UIImage+ImageEffects.h"

typedef enum _PWPhotoEditViewControllerSectionType {
    PWPhotoEditViewControllerSectionTypeEXIF,
    PWPhotoEditViewControllerSectionTypeTAG,
    PWPhotoEditViewControllerSectionTypeGPHOTO,
    PWPhotoEditViewControllerSectionTypeCOUNT
} PWPhotoEditViewControllerSectionType;

typedef enum _PWPhotoEditViewControllerExifType {
    PWPhotoEditViewControllerExifTypeDISTANCE,
    PWPhotoEditViewControllerExifTypeEXPOSURE,
    PWPhotoEditViewControllerExifTypeFLASH,
    PWPhotoEditViewControllerExifTypeFOCALLENGTH,
    PWPhotoEditViewControllerExifTypeFSTOP,
    PWPhotoEditViewControllerExifTypeIMAGEUNIQUEID,
    PWPhotoEditViewControllerExifTypeISO,
    PWPhotoEditViewControllerExifTypeMAKE,
    PWPhotoEditViewControllerExifTypeMODEL,
    PWPhotoEditViewControllerExifTypeTIME,
    PWPhotoEditViewControllerExifTypeCOUNT
} PWPhotoEditViewControllerExifType;

@interface PWPhotoEditViewController ()

@property (strong, nonatomic) PWPhotoObject *photo;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation PWPhotoEditViewController

- (id)initWithPhoto:(PWPhotoObject *)photo {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Info", nil);
        
        _photo = photo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *saveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(saveBarButtonItem)];
    self.navigationItem.rightBarButtonItem = saveBarButtonItem;
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelBarButtonItem)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)saveBarButtonItem {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelBarButtonItem {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableVeiwDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PWPhotoEditViewControllerSectionTypeCOUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case PWPhotoEditViewControllerSectionTypeEXIF:
            numberOfRows = PWPhotoEditViewControllerExifTypeCOUNT;
            break;
        case PWPhotoEditViewControllerSectionTypeGPHOTO:
//            numberOfRows
            break;
        case PWPhotoEditViewControllerSectionTypeTAG:
//            numberOfRows
            break;
        default:
            break;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    
    if (indexPath.section == PWPhotoEditViewControllerSectionTypeEXIF) {
        switch (indexPath.row) {
            case PWPhotoEditViewControllerExifTypeDISTANCE:
                cell.textLabel.text = @"Distance";
                cell.detailTextLabel.text = _photo.exif.distance;
                break;
            case PWPhotoEditViewControllerExifTypeEXPOSURE:
                cell.textLabel.text = @"Exposure";
                cell.detailTextLabel.text = _photo.exif.exposure;
                break;
            case PWPhotoEditViewControllerExifTypeFLASH:
                cell.textLabel.text = @"Flash";
                cell.detailTextLabel.text = _photo.exif.flash;
                break;
            case PWPhotoEditViewControllerExifTypeFOCALLENGTH:
                cell.textLabel.text = @"Focal Length";
                cell.detailTextLabel.text = _photo.exif.focallength;
                break;
            case PWPhotoEditViewControllerExifTypeFSTOP:
                cell.textLabel.text = @"Fstop";
                cell.detailTextLabel.text = _photo.exif.fstop;
                break;
            case PWPhotoEditViewControllerExifTypeIMAGEUNIQUEID:
                cell.textLabel.text = @"Image Unique ID";
                cell.detailTextLabel.text = _photo.exif.imageUniqueID;
                break;
            case PWPhotoEditViewControllerExifTypeISO:
                cell.textLabel.text = @"ISO";
                cell.detailTextLabel.text = _photo.exif.iso;
                break;
            case PWPhotoEditViewControllerExifTypeMAKE:
                cell.textLabel.text = @"Make";
                cell.detailTextLabel.text = _photo.exif.make;
                break;
            case PWPhotoEditViewControllerExifTypeMODEL:
                cell.textLabel.text = @"Model";
                cell.detailTextLabel.text = _photo.exif.model;
                break;
            case PWPhotoEditViewControllerExifTypeTIME:
                cell.textLabel.text = @"Time";
                cell.detailTextLabel.text = _photo.exif.time;
                break;
            default:
                break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case PWPhotoEditViewControllerSectionTypeEXIF:
            title = @"EXIF";
            break;
        case PWPhotoEditViewControllerSectionTypeGPHOTO:
            title = @"";
            break;
        case PWPhotoEditViewControllerSectionTypeTAG:
            title = @"TAG";
            break;
            
        default:
            break;
    }
    return title;
}

@end
