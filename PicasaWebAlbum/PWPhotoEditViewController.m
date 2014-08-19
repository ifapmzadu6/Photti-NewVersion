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
#import <SDImageCache.h>

typedef enum _PWPhotoEditViewControllerSectionType {
    PWPhotoEditViewControllerSectionTypeDESCRIPTION,
    PWPhotoEditViewControllerSectionTypeEXIForVIDEO,
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

typedef enum _PWPhotoEditViewControllerVIDEOType{
    PWPhotoEditViewControllerVIDEOTypeDURATION,
    PWPhotoEditViewControllerVIDEOTypeHEIGHT,
    PWPhotoEditViewControllerVIDEOTypeWIDTH,
    PWPhotoEditViewControllerVIDEOTypeFPS,
    PWPhotoEditViewControllerVIDEOTypeSAMPLERATE,
    PWPhotoEditViewControllerVIDEOTypeTYPE,
    PWPhotoEditViewControllerVIDEOTypeVIDEOCODEC,
    PWPhotoEditViewControllerVIDEOTypeAUDIOCODEC,
    PWPhotoEditViewControllerVIDEOTypeCHANNELS,
    PWPhotoEditViewControllerVIDEOTypeCOUNT
} PWPhotoEditViewControllerVIDEOType;

typedef enum _PWPhotoEditViewControllerDESCRIPTIONType {
    PWPhotoEditViewControllerDESCRIPTIONTypeTITLE,
    PWPhotoEditViewControllerDESCRIPTIONTypeTIMESTAMP,
    PWPhotoEditViewControllerDESCRIPTIONTypeSIZE,
    PWPhotoEditViewControllerDESCRIPTIONTypeHEIGHT,
    PWPhotoEditViewControllerDESCRIPTIONTypeWIDTH,
    PWPhotoEditViewControllerDESCRIPTIONTypeCREDIT,
    PWPhotoEditViewControllerDESCRIPTIONTypeSUMMARY,
    PWPhotoEditViewControllerDESCRIPTIONTypeKEYWORDS,
    PWPhotoEditViewControllerDESCRIPTIONTypeCOUNT
} PWPhotoEditViewControllerDESCRIPTIONType;


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
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
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
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableVeiwDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PWPhotoEditViewControllerSectionTypeCOUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case PWPhotoEditViewControllerSectionTypeEXIForVIDEO:
            if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
                numberOfRows = PWPhotoEditViewControllerExifTypeCOUNT;
            }
            else if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
                numberOfRows = PWPhotoEditViewControllerVIDEOTypeCOUNT;
            }
            break;
        case PWPhotoEditViewControllerSectionTypeDESCRIPTION:
            numberOfRows = PWPhotoEditViewControllerDESCRIPTIONTypeCOUNT;
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.alpha = 1.0f;
    
    if (indexPath.section == PWPhotoEditViewControllerSectionTypeEXIForVIDEO) {
        if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
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
        else if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
            switch (indexPath.row) {
                case PWPhotoEditViewControllerVIDEOTypeAUDIOCODEC:
                    cell.textLabel.text = @"Audio Codec";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_audioCodec;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeCHANNELS:
                    cell.textLabel.text = @"Channels";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_channels;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeDURATION:
                    cell.textLabel.text = @"Duration";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_duration;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeFPS:
                    cell.textLabel.text = @"FPS";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_fps;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeHEIGHT:
                    cell.textLabel.text = @"Height";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_height;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeSAMPLERATE:
                    cell.textLabel.text = @"Samplerate";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_samplingrate;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeTYPE:
                    cell.textLabel.text = @"Type";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_type;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeVIDEOCODEC:
                    cell.textLabel.text = @"Video Codec";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_videoCodec;
                    break;
                case PWPhotoEditViewControllerVIDEOTypeWIDTH:
                    cell.textLabel.text = @"Width";
                    cell.detailTextLabel.text = _photo.gphoto.originalvideo_width;
                    break;
                default:
                    break;
            }
        }
    }
    else if (indexPath.section == PWPhotoEditViewControllerSectionTypeDESCRIPTION) {
        switch (indexPath.row) {
            case PWPhotoEditViewControllerDESCRIPTIONTypeCREDIT:
                cell.textLabel.text = @"Credit";
                cell.detailTextLabel.text = _photo.media.credit;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeSUMMARY:
                cell.textLabel.text = @"Summary";
                cell.detailTextLabel.text = _photo.summary;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeKEYWORDS:
                cell.textLabel.text = @"Keywords";
                cell.detailTextLabel.text = _photo.media.keywords;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeTITLE:
                cell.textLabel.text = @"Title";
                cell.detailTextLabel.text = _photo.media.title;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeTIMESTAMP:
                cell.textLabel.text = @"Timestamp";
                cell.detailTextLabel.text = _photo.gphoto.timestamp;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeSIZE:
                cell.textLabel.text = @"Size";
                cell.detailTextLabel.text = _photo.gphoto.size.stringValue;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeHEIGHT:
                cell.textLabel.text = @"Height";
                cell.detailTextLabel.text = _photo.gphoto.height.stringValue;
                break;
            case PWPhotoEditViewControllerDESCRIPTIONTypeWIDTH:
                cell.textLabel.text = @"Width";
                cell.detailTextLabel.text = _photo.gphoto.width.stringValue;
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
        case PWPhotoEditViewControllerSectionTypeEXIForVIDEO:
            if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypePhoto) {
                title = @"EXIF";
            }
            else if (_photo.tag_type.integerValue == PWPhotoManagedObjectTypeVideo) {
                title = NSLocalizedString(@"Video", nil);
            }
            break;
        case PWPhotoEditViewControllerSectionTypeDESCRIPTION:
            title = NSLocalizedString(@"Description", nil);
            break;
        default:
            break;
    }
    return title;
}

@end
