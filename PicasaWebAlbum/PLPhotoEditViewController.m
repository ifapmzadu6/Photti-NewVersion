//
//  PLPhotoEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLPhotoEditViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLDateFormatter.h"
#import "PLModelObject.h"

#define NtN(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

typedef enum _PLPhotoEditViewControllerSectionType {
    PLPhotoEditViewControllerSectionTypeDESCRIPTION,
    PLPhotoEditViewControllerSectionTypeEXIF,
    PLPhotoEditViewControllerSectionTypeTIFF,
    PLPhotoEditViewControllerSectionTypeGPS,
    PLPhotoEditViewControllerSectionTypeCOUNT
} PLPhotoEditViewControllerSectionType;

typedef enum _PLPhotoEditViewControllerDescriptionType {
    PLPhotoEditViewControllerDescriptionTypeFILENAME,
    PLPhotoEditViewControllerDescriptionTypeDATE,
    PLPhotoEditViewControllerDescriptionTypeHEIGHT,
    PLPhotoEditViewControllerDescriptionTypeWIDTH,
    PLPhotoEditViewControllerDescriptionTypeDURATION,
    PLPhotoEditViewControllerDescriptionTypeCAPTION,
    PLPhotoEditViewControllerDescriptionTypeCOUNT
} PLPhotoEditViewControllerDescriptionType;

typedef enum _PLPhotoEditViewControllerExifType {
    PLPhotoEditViewControllerExifTypeAPERTUREVALUE,
    PLPhotoEditViewControllerExifTypeBRIGHTNESSVALUE,
    PLPhotoEditViewControllerExifTypeCOLORSPACE,
    PLPhotoEditViewControllerExifTypeCOMPONENTCSCONFIGURATION,
    PLPhotoEditViewControllerExifTypeDATETIMEORIGINAL,
    PLPhotoEditViewControllerExifTypeDATETIMEDEGITIZED,
    PLPhotoEditViewControllerExifTypeEXIFVERSION,
    PLPhotoEditViewControllerExifTypeEXPOSUREMODE,
    PLPhotoEditViewControllerExifTypeEXPOSUREPROGRAM,
    PLPhotoEditViewControllerExifTypeEXPOSURETIME,
    PLPhotoEditViewControllerExifTypeFNUMBER,
    PLPhotoEditViewControllerExifTypeFLASH,
    PLPhotoEditViewControllerExifTypeFLASHPIXVERSION,
    PLPhotoEditViewControllerExifTypeFOCALLENIN35MMFILM,
    PLPhotoEditViewControllerExifTypeFOCALLENGTH,
    PLPhotoEditViewControllerExifTypeISOSPEEDRATINGS,
    PLPhotoEditViewControllerExifTypeLENSMAKE,
    PLPhotoEditViewControllerExifTypeLENSMODEL,
    PLPhotoEditViewControllerExifTypeLENSSPICIFICATION,
    PLPhotoEditViewControllerExifTypeMETERINGMODE,
    PLPhotoEditViewControllerExifTypePIXELXDIMENTION,
    PLPhotoEditViewControllerExifTypePIXELYDIMENTION,
    PLPhotoEditViewControllerExifTypeSCENECAPTURETYPE,
    PLPhotoEditViewControllerExifTypeSCENETYPE,
    PLPhotoEditViewControllerExifTypeSENSINGMETHODS,
    PLPhotoEditViewControllerExifTypeSHUTTERSPEEDVALUE,
    PLPhotoEditViewControllerExifTypeSUBJECTAREA,
    PLPhotoEditViewControllerExifTypeSUBSECTIMEDEGITIZED,
    PLPhotoEditViewControllerExifTypeSUBSECTIMEORIGINAL,
    PLPhotoEditViewControllerExifTypeWHITEBALANCE,
    PLPhotoEditViewControllerExifTypeCOUNT
} PLPhotoEditViewControllerExifType;

typedef enum _PLPhotoEditViewControllerTiffType{
    PLPhotoEditViewControllerTiffTypeDATETIME,
    PLPhotoEditViewControllerTiffTypeMAKE,
    PLPhotoEditViewControllerTiffTypeMODEL,
    PLPhotoEditViewControllerTiffTypeORIENTATION,
    PLPhotoEditViewControllerTiffTypeRESOLUTIONUNIT,
    PLPhotoEditViewControllerTiffTypeSOFTWARE,
    PLPhotoEditViewControllerTiffTypeXRESOLUTION,
    PLPhotoEditViewControllerTiffTypeYRESOLUTION,
    PLPhotoEditViewControllerTiffTypeCOUNT
} PLPhotoEditViewControllerTiffType;

typedef enum _PLPhotoEditViewControllerGPSType {
    PLPhotoEditViewControllerGPSTypeALTITUDE,
    PLPhotoEditViewControllerGPSTypeALTITUDEREF,
    PLPhotoEditViewControllerGPSTypeDATESTAMP,
    PLPhotoEditViewControllerGPSTypeLATITUDE,
    PLPhotoEditViewControllerGPSTypeLATITUDEREF,
    PLPhotoEditViewControllerGPSTypeLONGITUDE,
    PLPhotoEditViewControllerGPSTypeLONGITUDEREF,
    PLPhotoEditViewControllerGPSTypeTIMESTAMP,
    PLPhotoEditViewControllerGPSTypeCOUNT
} PLPhotoEditViewControllerGPSType;

@interface PLPhotoEditViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) PLPhotoObject *photo;
@property (strong, nonatomic) NSDictionary *metadata;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation PLPhotoEditViewController

- (id)initWithPhoto:(PLPhotoObject *)photo metadata:(NSDictionary *)metadata {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Info", nil);
        
        _photo = photo;
        _metadata = metadata;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_tableView];
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
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PLPhotoEditViewControllerSectionTypeCOUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case PLPhotoEditViewControllerSectionTypeDESCRIPTION:
            numberOfRows = PLPhotoEditViewControllerDescriptionTypeCOUNT;
            break;
        case PLPhotoEditViewControllerSectionTypeEXIF:
            numberOfRows = PLPhotoEditViewControllerExifTypeCOUNT;
            break;
        case PLPhotoEditViewControllerSectionTypeTIFF:
            numberOfRows = PLPhotoEditViewControllerTiffTypeCOUNT;
            break;
        case PLPhotoEditViewControllerSectionTypeGPS:
            numberOfRows = PLPhotoEditViewControllerGPSTypeCOUNT;
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
    cell.textLabel.alpha = 1.0f;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == PLPhotoEditViewControllerSectionTypeDESCRIPTION) {
        switch (indexPath.row) {
            case PLPhotoEditViewControllerDescriptionTypeFILENAME:
                cell.textLabel.text = NSLocalizedString(@"File Name", nil);
                cell.detailTextLabel.text = _photo.filename;
                break;
            case PLPhotoEditViewControllerDescriptionTypeCAPTION:
                cell.textLabel.text = NSLocalizedString(@"Caption", nil);
                cell.detailTextLabel.text = _photo.caption;
                break;
            case PLPhotoEditViewControllerDescriptionTypeDATE:
                cell.textLabel.text = NSLocalizedString(@"Date", nil);
                cell.detailTextLabel.text = [[PLDateFormatter formatter] stringFromDate:_photo.date];
                break;
            case PLPhotoEditViewControllerDescriptionTypeDURATION:
                cell.textLabel.text = NSLocalizedString(@"Duration", nil);
                cell.detailTextLabel.text = _photo.duration.stringValue;
                break;
            case PLPhotoEditViewControllerDescriptionTypeHEIGHT:
                cell.textLabel.text = NSLocalizedString(@"Height", nil);
                cell.detailTextLabel.text = _photo.height.stringValue;
                break;
            case PLPhotoEditViewControllerDescriptionTypeWIDTH:
                cell.textLabel.text = NSLocalizedString(@"Width", nil);
                cell.detailTextLabel.text = _photo.width.stringValue;
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == PLPhotoEditViewControllerSectionTypeEXIF) {
        NSDictionary *exif = NtN(_metadata[@"{Exif}"]);
        switch (indexPath.row) {
            case PLPhotoEditViewControllerExifTypeAPERTUREVALUE:
                cell.textLabel.text = NSLocalizedString(@"ApertureValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ApertureValue"]];
                break;
            case PLPhotoEditViewControllerExifTypeBRIGHTNESSVALUE:
                cell.textLabel.text = NSLocalizedString(@"BrightnessValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"BrightnessValue"]];
                break;
            case PLPhotoEditViewControllerExifTypeCOLORSPACE:
                cell.textLabel.text = NSLocalizedString(@"ColorSpace", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ColorSpace"]];
                break;
            case PLPhotoEditViewControllerExifTypeCOMPONENTCSCONFIGURATION:
                cell.textLabel.text = NSLocalizedString(@"ComponentsConfiguration", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ComponentsConfiguration"]];
                break;
            case PLPhotoEditViewControllerExifTypeDATETIMEDEGITIZED:
                cell.textLabel.text = NSLocalizedString(@"DateTimeDigitized", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"DateTimeDigitized"]];
                break;
            case PLPhotoEditViewControllerExifTypeDATETIMEORIGINAL:
                cell.textLabel.text = NSLocalizedString(@"DateTimeOriginal", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"DateTimeOriginal"]];
                break;
            case PLPhotoEditViewControllerExifTypeEXIFVERSION:
                cell.textLabel.text = NSLocalizedString(@"ExifVersion", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExifVersion"]];
                break;
            case PLPhotoEditViewControllerExifTypeEXPOSUREMODE:
                cell.textLabel.text = NSLocalizedString(@"ExposureMode", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureMode"]];
                break;
            case PLPhotoEditViewControllerExifTypeEXPOSUREPROGRAM:
                cell.textLabel.text = NSLocalizedString(@"ExposureProgram", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureProgram"]];
                break;
            case PLPhotoEditViewControllerExifTypeEXPOSURETIME:
                cell.textLabel.text = NSLocalizedString(@"ExposureTime", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ExposureTime"]];
                break;
            case PLPhotoEditViewControllerExifTypeFLASH:
                cell.textLabel.text = NSLocalizedString(@"Flash", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"Flash"]];
                break;
            case PLPhotoEditViewControllerExifTypeFLASHPIXVERSION:
                cell.textLabel.text = NSLocalizedString(@"FlashPixVersion", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FlashPixVersion"]];
                break;
            case PLPhotoEditViewControllerExifTypeFNUMBER:
                cell.textLabel.text = NSLocalizedString(@"FNumber", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FNumber"]];
                break;
            case PLPhotoEditViewControllerExifTypeFOCALLENGTH:
                cell.textLabel.text = NSLocalizedString(@"FocalLength", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FocalLength"]];
                break;
            case PLPhotoEditViewControllerExifTypeFOCALLENIN35MMFILM:
                cell.textLabel.text = NSLocalizedString(@"FocalLenIn35mmFilm", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"FocalLenIn35mmFilm"]];
                break;
            case PLPhotoEditViewControllerExifTypeISOSPEEDRATINGS:
                cell.textLabel.text = NSLocalizedString(@"ISOSpeedRatings", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ISOSpeedRatings"]];
                break;
            case PLPhotoEditViewControllerExifTypeLENSMAKE:
                cell.textLabel.text = NSLocalizedString(@"LensMake", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensMake"]];
                break;
            case PLPhotoEditViewControllerExifTypeLENSMODEL:
                cell.textLabel.text = NSLocalizedString(@"LensModel", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensModel"]];
                break;
            case PLPhotoEditViewControllerExifTypeLENSSPICIFICATION:
                cell.textLabel.text = NSLocalizedString(@"LensSpecification", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"LensSpecification"]];
                break;
            case PLPhotoEditViewControllerExifTypeMETERINGMODE:
                cell.textLabel.text = NSLocalizedString(@"MeteringMode", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"MeteringMode"]];
                break;
            case PLPhotoEditViewControllerExifTypePIXELXDIMENTION:
                cell.textLabel.text = NSLocalizedString(@"PixelXDimension", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"PixelXDimension"]];
                break;
            case PLPhotoEditViewControllerExifTypePIXELYDIMENTION:
                cell.textLabel.text = NSLocalizedString(@"PixelYDimension", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"PixelYDimension"]];
                break;
            case PLPhotoEditViewControllerExifTypeSCENECAPTURETYPE:
                cell.textLabel.text = NSLocalizedString(@"SceneCaptureType", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SceneCaptureType"]];
                break;
            case PLPhotoEditViewControllerExifTypeSCENETYPE:
                cell.textLabel.text = NSLocalizedString(@"SceneType", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SceneType"]];
                break;
            case PLPhotoEditViewControllerExifTypeSENSINGMETHODS:
                cell.textLabel.text = NSLocalizedString(@"SensingMethod", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SensingMethod"]];
                break;
            case PLPhotoEditViewControllerExifTypeSHUTTERSPEEDVALUE:
                cell.textLabel.text = NSLocalizedString(@"ShutterSpeedValue", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"ShutterSpeedValue"]];
                break;
            case PLPhotoEditViewControllerExifTypeSUBJECTAREA:
                cell.textLabel.text = NSLocalizedString(@"SubjectArea", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubjectArea"]];
                break;
            case PLPhotoEditViewControllerExifTypeSUBSECTIMEDEGITIZED:
                cell.textLabel.text = NSLocalizedString(@"SubsecTimeDigitized", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubsecTimeDigitized"]];
                break;
            case PLPhotoEditViewControllerExifTypeSUBSECTIMEORIGINAL:
                cell.textLabel.text = NSLocalizedString(@"SubsecTimeOriginal", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"SubsecTimeOriginal"]];
                break;
            case PLPhotoEditViewControllerExifTypeWHITEBALANCE:
                cell.textLabel.text = NSLocalizedString(@"WhiteBalance", nil);
                cell.detailTextLabel.text = [self stringFromObject:exif[@"WhiteBalance"]];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == PLPhotoEditViewControllerSectionTypeTIFF) {
        NSDictionary *tiff = NtN(_metadata[@"{TIFF}"]);
        switch (indexPath.row) {
            case PLPhotoEditViewControllerTiffTypeDATETIME:
                cell.textLabel.text = NSLocalizedString(@"DateTime", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"DateTime"]];
                break;
            case PLPhotoEditViewControllerTiffTypeMAKE:
                cell.textLabel.text = NSLocalizedString(@"Make", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Make"]];
                break;
            case PLPhotoEditViewControllerTiffTypeMODEL:
                cell.textLabel.text = NSLocalizedString(@"Model", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Model"]];
                break;
            case PLPhotoEditViewControllerTiffTypeORIENTATION:
                cell.textLabel.text = NSLocalizedString(@"Orientation", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Orientation"]];
                break;
            case PLPhotoEditViewControllerTiffTypeRESOLUTIONUNIT:
                cell.textLabel.text = NSLocalizedString(@"ResolutionUnit", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"ResolutionUnit"]];
                break;
            case PLPhotoEditViewControllerTiffTypeSOFTWARE:
                cell.textLabel.text = NSLocalizedString(@"Software", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"Software"]];
                break;
            case PLPhotoEditViewControllerTiffTypeXRESOLUTION:
                cell.textLabel.text = NSLocalizedString(@"XResolution", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"XResolution"]];
                break;
            case PLPhotoEditViewControllerTiffTypeYRESOLUTION:
                cell.textLabel.text = NSLocalizedString(@"YResolution", nil);
                cell.detailTextLabel.text = [self stringFromObject:tiff[@"YResolution"]];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == PLPhotoEditViewControllerSectionTypeGPS) {
        NSDictionary *gps = NtN(_metadata[@"{GPS}"]);
        switch (indexPath.row) {
            case PLPhotoEditViewControllerGPSTypeALTITUDE:
                cell.textLabel.text = NSLocalizedString(@"Altitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Altitude"]];
                break;
            case PLPhotoEditViewControllerGPSTypeALTITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"AltitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"AltitudeRef"]];
                break;
            case PLPhotoEditViewControllerGPSTypeDATESTAMP:
                cell.textLabel.text = NSLocalizedString(@"DateStamp", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"DateStamp"]];
                break;
            case PLPhotoEditViewControllerGPSTypeLATITUDE:
                cell.textLabel.text = NSLocalizedString(@"Latitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Latitude"]];
                break;
            case PLPhotoEditViewControllerGPSTypeLATITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"LatitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"LatitudeRef"]];
                break;
            case PLPhotoEditViewControllerGPSTypeLONGITUDE:
                cell.textLabel.text = NSLocalizedString(@"Longitude", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"Longitude"]];
                break;
            case PLPhotoEditViewControllerGPSTypeLONGITUDEREF:
                cell.textLabel.text = NSLocalizedString(@"LongitudeRef", nil);
                cell.detailTextLabel.text = [self stringFromObject:gps[@"LongitudeRef"]];
                break;
            case PLPhotoEditViewControllerGPSTypeTIMESTAMP:
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
        case PLPhotoEditViewControllerSectionTypeDESCRIPTION:
            title = NSLocalizedString(@"Description", nil);
            break;
        case PLPhotoEditViewControllerSectionTypeEXIF:
            title = @"EXIF";
            break;
        case PLPhotoEditViewControllerSectionTypeTIFF:
            title = @"TIFF";
            break;
        case PLPhotoEditViewControllerSectionTypeGPS:
            title = @"GPS";
            break;
        default:
            break;
    }
    return title;
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
