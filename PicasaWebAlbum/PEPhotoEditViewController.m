//
//  PEPhotoEditViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/09.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoEditViewController.h"

#import "PAColors.h"
#import "PADateFormatter.h"
#import "UIImage+ImageEffects.h"

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

typedef enum _PEPhotoEditViewControllerSectionType {
    PEPhotoEditViewControllerSectionTypeDESCRIPTION,
    PEPhotoEditViewControllerSectionTypeEXIF,
    PEPhotoEditViewControllerSectionTypeTIFF,
    PEPhotoEditViewControllerSectionTypeGPS,
    PEPhotoEditViewControllerSectionTypeCOUNT
} PEPhotoEditViewControllerSectionType;

typedef enum _PEPhotoEditViewControllerDescriptionType {
    PEPhotoEditViewControllerDescriptionTypeFILENAME,
    PEPhotoEditViewControllerDescriptionTypeDATE,
    PEPhotoEditViewControllerDescriptionTypeHEIGHT,
    PEPhotoEditViewControllerDescriptionTypeWIDTH,
    PEPhotoEditViewControllerDescriptionTypeDURATION,
    PEPhotoEditViewControllerDescriptionTypeCAPTION,
    PEPhotoEditViewControllerDescriptionTypeCOUNT
} PEPhotoEditViewControllerDescriptionType;

typedef enum _PEPhotoEditViewControllerExifType {
    PEPhotoEditViewControllerExifTypeAPERTUREVALUE,
    PEPhotoEditViewControllerExifTypeBRIGHTNESSVALUE,
    PEPhotoEditViewControllerExifTypeCOLORSPACE,
    PEPhotoEditViewControllerExifTypeCOMPONENTCSCONFIGURATION,
    PEPhotoEditViewControllerExifTypeDATETIMEORIGINAL,
    PEPhotoEditViewControllerExifTypeDATETIMEDEGITIZED,
    PEPhotoEditViewControllerExifTypeEXIFVERSION,
    PEPhotoEditViewControllerExifTypeEXPOSUREMODE,
    PEPhotoEditViewControllerExifTypeEXPOSUREPROGRAM,
    PEPhotoEditViewControllerExifTypeEXPOSURETIME,
    PEPhotoEditViewControllerExifTypeFNUMBER,
    PEPhotoEditViewControllerExifTypeFLASH,
    PEPhotoEditViewControllerExifTypeFLASHPIXVERSION,
    PEPhotoEditViewControllerExifTypeFOCALLENIN35MMFILM,
    PEPhotoEditViewControllerExifTypeFOCALLENGTH,
    PEPhotoEditViewControllerExifTypeISOSPEEDRATINGS,
    PEPhotoEditViewControllerExifTypeLENSMAKE,
    PEPhotoEditViewControllerExifTypeLENSMODEL,
    PEPhotoEditViewControllerExifTypeLENSSPICIFICATION,
    PEPhotoEditViewControllerExifTypeMETERINGMODE,
    PEPhotoEditViewControllerExifTypePIXELXDIMENTION,
    PEPhotoEditViewControllerExifTypePIXELYDIMENTION,
    PEPhotoEditViewControllerExifTypeSCENECAPTURETYPE,
    PEPhotoEditViewControllerExifTypeSCENETYPE,
    PEPhotoEditViewControllerExifTypeSENSINGMETHODS,
    PEPhotoEditViewControllerExifTypeSHUTTERSPEEDVALUE,
    PEPhotoEditViewControllerExifTypeSUBJECTAREA,
    PEPhotoEditViewControllerExifTypeSUBSECTIMEDEGITIZED,
    PEPhotoEditViewControllerExifTypeSUBSECTIMEORIGINAL,
    PEPhotoEditViewControllerExifTypeWHITEBALANCE,
    PEPhotoEditViewControllerExifTypeCOUNT
} PEPhotoEditViewControllerExifType;

typedef enum _PEPhotoEditViewControllerTiffType{
    PEPhotoEditViewControllerTiffTypeDATETIME,
    PEPhotoEditViewControllerTiffTypeMAKE,
    PEPhotoEditViewControllerTiffTypeMODEL,
    PEPhotoEditViewControllerTiffTypeORIENTATION,
    PEPhotoEditViewControllerTiffTypeRESOLUTIONUNIT,
    PEPhotoEditViewControllerTiffTypeSOFTWARE,
    PEPhotoEditViewControllerTiffTypeXRESOLUTION,
    PEPhotoEditViewControllerTiffTypeYRESOLUTION,
    PEPhotoEditViewControllerTiffTypeCOUNT
} PEPhotoEditViewControllerTiffType;

typedef enum _PEPhotoEditViewControllerGPSType {
    PEPhotoEditViewControllerGPSTypeALTITUDE,
    PEPhotoEditViewControllerGPSTypeALTITUDEREF,
    PEPhotoEditViewControllerGPSTypeDATESTAMP,
    PEPhotoEditViewControllerGPSTypeLATITUDE,
    PEPhotoEditViewControllerGPSTypeLATITUDEREF,
    PEPhotoEditViewControllerGPSTypeLONGITUDE,
    PEPhotoEditViewControllerGPSTypeLONGITUDEREF,
    PEPhotoEditViewControllerGPSTypeTIMESTAMP,
    PEPhotoEditViewControllerGPSTypeCOUNT
} PEPhotoEditViewControllerGPSType;

@interface PEPhotoEditViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) NSDictionary *metadata;
@property (strong, nonatomic) UIImage *backgroundImage;

@end

@implementation PEPhotoEditViewController

- (instancetype)initWithAsset:(PHAsset *)asset metadata:(NSDictionary *)metadata {
    self = [self initWithAsset:asset metadata:metadata backgroundScreenShot:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithAsset:(PHAsset *)asset metadata:(NSDictionary *)metadata backgroundScreenShot:(UIImage *)backgroundScreenshot {
    self = [self init];
    if (self) {
        self.title = NSLocalizedString(@"Info", nil);
        
        _asset = asset;
        _metadata = metadata;
        if (backgroundScreenshot) {
            UIColor *tintColor = [UIColor colorWithWhite:0.5f alpha:0.3f];
            _backgroundImage = [backgroundScreenshot applyBlurWithRadius:25 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    BOOL isBackgroundImageEnable = (_backgroundImage) ? YES : NO;
    if (isBackgroundImageEnable) {
        _backgroundImageView = [UIImageView new];
        _backgroundImageView.image = _backgroundImage;
        [self.view addSubview:_backgroundImageView];
        _backgroundImage = nil;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [[PAColors getColor:PAColorsTypeTextColor] colorWithAlphaComponent:0.1f];
    _tableView.separatorColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    CGFloat navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    _tableView.contentInset = UIEdgeInsetsMake(navigationBarHeight + statusBarHeight, 0.0f, 0.0f, 0.0f);
    _tableView.contentOffset = CGPointMake(0.0f, -_tableView.contentInset.top);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    [self.view addSubview:_tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _backgroundImageView.frame = rect;
    
    CGFloat navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (!self.isPhone) {
        statusBarHeight = 0.0f;
    }
    _tableView.contentInset = UIEdgeInsetsMake(navigationBarHeight + statusBarHeight, 0.0f, 0.0f, 0.0f);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    _tableView.frame = rect;
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PEPhotoEditViewControllerSectionTypeCOUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case PEPhotoEditViewControllerSectionTypeDESCRIPTION:
            numberOfRows = PEPhotoEditViewControllerDescriptionTypeCOUNT;
            break;
        case PEPhotoEditViewControllerSectionTypeEXIF:
            numberOfRows = PEPhotoEditViewControllerExifTypeCOUNT;
            break;
        case PEPhotoEditViewControllerSectionTypeTIFF:
            numberOfRows = PEPhotoEditViewControllerTiffTypeCOUNT;
            break;
        case PEPhotoEditViewControllerSectionTypeGPS:
            numberOfRows = PEPhotoEditViewControllerGPSTypeCOUNT;
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
        cell.textLabel.textColor = [PAColors getColor:PAColorsTypeBackgroundColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.detailTextLabel.textColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    }
    cell.textLabel.alpha = 1.0f;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
    
    if (indexPath.section == PEPhotoEditViewControllerSectionTypeDESCRIPTION) {
        switch (indexPath.row) {
            case PEPhotoEditViewControllerDescriptionTypeDATE: {
                cell.textLabel.text = NSLocalizedString(@"Date", nil);
                cell.detailTextLabel.text = [[PADateFormatter fullStringFormatter] stringFromDate:_asset.creationDate];
                break;
            }
            case PEPhotoEditViewControllerDescriptionTypeDURATION: {
                cell.textLabel.text = NSLocalizedString(@"Duration", nil);
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lf", _asset.duration];
                break;
            }
            case PEPhotoEditViewControllerDescriptionTypeHEIGHT: {
                cell.textLabel.text = NSLocalizedString(@"Height", nil);
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)_asset.pixelHeight];
                break;
            }
            case PEPhotoEditViewControllerDescriptionTypeWIDTH: {
                cell.textLabel.text = NSLocalizedString(@"Width", nil);
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)_asset.pixelWidth];
                break;
            }
            default:
                break;
        }
    }
    else if (indexPath.section == PEPhotoEditViewControllerSectionTypeEXIF) {
        NSDictionary *exif = NtN(_metadata[@"{Exif}"]);
        switch (indexPath.row) {
            case PEPhotoEditViewControllerExifTypeAPERTUREVALUE:
                cell.textLabel.text = NSLocalizedString(@"ApertureValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ApertureValue"]];
                break;
            case PEPhotoEditViewControllerExifTypeBRIGHTNESSVALUE:
                cell.textLabel.text = NSLocalizedString(@"BrightnessValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"BrightnessValue"]];
                break;
            case PEPhotoEditViewControllerExifTypeCOLORSPACE:
                cell.textLabel.text = NSLocalizedString(@"ColorSpace", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ColorSpace"]];
                break;
            case PEPhotoEditViewControllerExifTypeCOMPONENTCSCONFIGURATION:
                cell.textLabel.text = NSLocalizedString(@"ComponentsConfiguration", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ComponentsConfiguration"]];
                break;
            case PEPhotoEditViewControllerExifTypeDATETIMEDEGITIZED:
                cell.textLabel.text = NSLocalizedString(@"DateTimeDigitized", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"DateTimeDigitized"]];
                break;
            case PEPhotoEditViewControllerExifTypeDATETIMEORIGINAL:
                cell.textLabel.text = NSLocalizedString(@"DateTimeOriginal", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"DateTimeOriginal"]];
                break;
            case PEPhotoEditViewControllerExifTypeEXIFVERSION:
                cell.textLabel.text = NSLocalizedString(@"ExifVersion", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExifVersion"]];
                break;
            case PEPhotoEditViewControllerExifTypeEXPOSUREMODE:
                cell.textLabel.text = NSLocalizedString(@"ExposureMode", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureMode"]];
                break;
            case PEPhotoEditViewControllerExifTypeEXPOSUREPROGRAM:
                cell.textLabel.text = NSLocalizedString(@"ExposureProgram", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureProgram"]];
                break;
            case PEPhotoEditViewControllerExifTypeEXPOSURETIME:
                cell.textLabel.text = NSLocalizedString(@"ExposureTime", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureTime"]];
                break;
            case PEPhotoEditViewControllerExifTypeFLASH:
                cell.textLabel.text = NSLocalizedString(@"Flash", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"Flash"]];
                break;
            case PEPhotoEditViewControllerExifTypeFLASHPIXVERSION:
                cell.textLabel.text = NSLocalizedString(@"FlashPixVersion", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FlashPixVersion"]];
                break;
            case PEPhotoEditViewControllerExifTypeFNUMBER:
                cell.textLabel.text = NSLocalizedString(@"FNumber", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FNumber"]];
                break;
            case PEPhotoEditViewControllerExifTypeFOCALLENGTH:
                cell.textLabel.text = NSLocalizedString(@"FocalLength", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FocalLength"]];
                break;
            case PEPhotoEditViewControllerExifTypeFOCALLENIN35MMFILM:
                cell.textLabel.text = NSLocalizedString(@"FocalLenIn35mmFilm", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FocalLenIn35mmFilm"]];
                break;
            case PEPhotoEditViewControllerExifTypeISOSPEEDRATINGS:
                cell.textLabel.text = NSLocalizedString(@"ISOSpeedRatings", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ISOSpeedRatings"]];
                break;
            case PEPhotoEditViewControllerExifTypeLENSMAKE:
                cell.textLabel.text = NSLocalizedString(@"LensMake", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensMake"]];
                break;
            case PEPhotoEditViewControllerExifTypeLENSMODEL:
                cell.textLabel.text = NSLocalizedString(@"LensModel", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensModel"]];
                break;
            case PEPhotoEditViewControllerExifTypeLENSSPICIFICATION:
                cell.textLabel.text = NSLocalizedString(@"LensSpecification", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensSpecification"]];
                break;
            case PEPhotoEditViewControllerExifTypeMETERINGMODE:
                cell.textLabel.text = NSLocalizedString(@"MeteringMode", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"MeteringMode"]];
                break;
            case PEPhotoEditViewControllerExifTypePIXELXDIMENTION:
                cell.textLabel.text = NSLocalizedString(@"PixelXDimension", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"PixelXDimension"]];
                break;
            case PEPhotoEditViewControllerExifTypePIXELYDIMENTION:
                cell.textLabel.text = NSLocalizedString(@"PixelYDimension", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"PixelYDimension"]];
                break;
            case PEPhotoEditViewControllerExifTypeSCENECAPTURETYPE:
                cell.textLabel.text = NSLocalizedString(@"SceneCaptureType", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SceneCaptureType"]];
                break;
            case PEPhotoEditViewControllerExifTypeSCENETYPE:
                cell.textLabel.text = NSLocalizedString(@"SceneType", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SceneType"]];
                break;
            case PEPhotoEditViewControllerExifTypeSENSINGMETHODS:
                cell.textLabel.text = NSLocalizedString(@"SensingMethod", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SensingMethod"]];
                break;
            case PEPhotoEditViewControllerExifTypeSHUTTERSPEEDVALUE:
                cell.textLabel.text = NSLocalizedString(@"ShutterSpeedValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ShutterSpeedValue"]];
                break;
            case PEPhotoEditViewControllerExifTypeSUBJECTAREA:
                cell.textLabel.text = NSLocalizedString(@"SubjectArea", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubjectArea"]];
                break;
            case PEPhotoEditViewControllerExifTypeSUBSECTIMEDEGITIZED:
                cell.textLabel.text = NSLocalizedString(@"SubsecTimeDigitized", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubsecTimeDigitized"]];
                break;
            case PEPhotoEditViewControllerExifTypeSUBSECTIMEORIGINAL:
                cell.textLabel.text = NSLocalizedString(@"SubsecTimeOriginal", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubsecTimeOriginal"]];
                break;
            case PEPhotoEditViewControllerExifTypeWHITEBALANCE:
                cell.textLabel.text = NSLocalizedString(@"WhiteBalance", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"WhiteBalance"]];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == PEPhotoEditViewControllerSectionTypeTIFF) {
        NSDictionary *tiff = NtN(_metadata[@"{TIFF}"]);
        switch (indexPath.row) {
            case PEPhotoEditViewControllerTiffTypeDATETIME:
                cell.textLabel.text = NSLocalizedString(@"DateTime", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"DateTime"]];
                break;
            case PEPhotoEditViewControllerTiffTypeMAKE:
                cell.textLabel.text = NSLocalizedString(@"Make", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Make"]];
                break;
            case PEPhotoEditViewControllerTiffTypeMODEL:
                cell.textLabel.text = NSLocalizedString(@"Model", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Model"]];
                break;
            case PEPhotoEditViewControllerTiffTypeORIENTATION:
                cell.textLabel.text = NSLocalizedString(@"Orientation", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Orientation"]];
                break;
            case PEPhotoEditViewControllerTiffTypeRESOLUTIONUNIT:
                cell.textLabel.text = NSLocalizedString(@"ResolutionUnit", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"ResolutionUnit"]];
                break;
            case PEPhotoEditViewControllerTiffTypeSOFTWARE:
                cell.textLabel.text = NSLocalizedString(@"Software", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Software"]];
                break;
            case PEPhotoEditViewControllerTiffTypeXRESOLUTION:
                cell.textLabel.text = NSLocalizedString(@"XResolution", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"XResolution"]];
                break;
            case PEPhotoEditViewControllerTiffTypeYRESOLUTION:
                cell.textLabel.text = NSLocalizedString(@"YResolution", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"YResolution"]];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == PEPhotoEditViewControllerSectionTypeGPS) {
        NSDictionary *gps = NtN(_metadata[@"{GPS}"]);
        switch (indexPath.row) {
            case PEPhotoEditViewControllerGPSTypeALTITUDE:
                cell.textLabel.text = NSLocalizedString(@"Altitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Altitude"]];
                break;
            case PEPhotoEditViewControllerGPSTypeALTITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"AltitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"AltitudeRef"]];
                break;
            case PEPhotoEditViewControllerGPSTypeDATESTAMP:
                cell.textLabel.text = NSLocalizedString(@"DateStamp", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"DateStamp"]];
                break;
            case PEPhotoEditViewControllerGPSTypeLATITUDE:
                cell.textLabel.text = NSLocalizedString(@"Latitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Latitude"]];
                break;
            case PEPhotoEditViewControllerGPSTypeLATITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"LatitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"LatitudeRef"]];
                break;
            case PEPhotoEditViewControllerGPSTypeLONGITUDE:
                cell.textLabel.text = NSLocalizedString(@"Longitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Longitude"]];
                break;
            case PEPhotoEditViewControllerGPSTypeLONGITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"LongitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"LongitudeRef"]];
                break;
            case PEPhotoEditViewControllerGPSTypeTIMESTAMP:
                cell.textLabel.text = NSLocalizedString(@"TimeStamp", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"TimeStamp"]];
                break;
            default:
                break;
        }
    }
    
    if (!cell.detailTextLabel.text) {
        cell.textLabel.alpha = 0.25f;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case PEPhotoEditViewControllerSectionTypeDESCRIPTION:
            title = NSLocalizedString(@"Description", nil);
            break;
        case PEPhotoEditViewControllerSectionTypeEXIF:
            title = @"EXIF";
            break;
        case PEPhotoEditViewControllerSectionTypeTIFF:
            title = @"TIFF";
            break;
        case PEPhotoEditViewControllerSectionTypeGPS:
            title = @"GPS";
            break;
        default:
            break;
    }
    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[PAColors getColor:PAColorsTypeBackgroundColor]];
}

#pragma mark METHODS
- (NSString *)stringFromObject:(id)object {
    if (!object) return nil;
    object = NtN(object);
    
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)object).stringValue;
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        return [((NSArray *)object) componentsJoinedByString:@","];
    }
    
    return nil;
}

@end
