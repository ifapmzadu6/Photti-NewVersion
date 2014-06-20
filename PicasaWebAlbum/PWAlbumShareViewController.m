//
//  PWAlbumShareViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumShareViewController.h"

#import "PWColors.h"

@interface PWAlbumShareViewController ()

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) PWAlbumObject *album;

@property (nonatomic) NSUInteger selectedIndex;

@end

@implementation PWAlbumShareViewController

- (id)initWithAlbum:(PWAlbumObject *)album {
    self = [super init];
    if (self) {
        _album = album;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = _album.title;
    
    for (NSString *access in [self arrayOfAccess]) {
        if ([access isEqualToString:_album.gphoto.access]) {
            _selectedIndex = [[self arrayOfAccess] indexOfObject:access];
        }
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.leftBarButtonItem = doneBarButtonItem;
    
    self.navigationController.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    }
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    cell.textLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if (indexPath.section == 0) {
        NSString *key = [[self arrayOfAccess] objectAtIndex:indexPath.row];
        cell.textLabel.text = [[self dictionaryOfAccessDesplayString] objectForKey:key];
        if (indexPath.row == _selectedIndex) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.textLabel.textColor = [[PWColors getColor:PWColorsTypeTextColor] colorWithAlphaComponent:0.8f];
        }
    }
    else {
        if (indexPath.row == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
            NSString *link = nil;
            if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
                for (PWPhotoLinkObject *linkObject in _album.link) {
                    if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                        link = linkObject.href;
                    }
                }
            }
            if (!link) {
                cell.textLabel.text = @"http://";
                cell.textLabel.textColor = [[PWColors getColor:PWColorsTypeTextColor] colorWithAlphaComponent:0.5f];
            }
            else {
                cell.textLabel.text = link;
                cell.textLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
            }
        }
        else {
            cell.textLabel.text = NSLocalizedString(@"Share link", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            NSString *link = nil;
            if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
                for (PWPhotoLinkObject *linkObject in _album.link) {
                    if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                        link = linkObject.href;
                    }
                }
            }
            if (link) {
                cell.textLabel.textColor = cell.tintColor;
            }
            else {
                cell.textLabel.textColor = [[PWColors getColor:PWColorsTypeTextColor] colorWithAlphaComponent:0.5f];
            }
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Setting", nil);
    }
    return NSLocalizedString(@"Link", nil);
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == _selectedIndex) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"情報を変更しています", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
        [indicator startAnimating];
        [alertView setValue:indicator forKey:@"accessoryView"];
        [alertView show];
        
        NSString *access = [[self arrayOfAccess] objectAtIndex:indexPath.row];
        __weak typeof(self) wself = self;
        [PWPicasaAPI putModifyingAlbumWithID:_album.id_str
                                       title:nil
                                     summary:nil
                                    location:nil
                                      access:access
                                   timestamp:nil
                                    keywords:nil
                                  completion:^(NSString *newAccess, NSSet *link, NSError *error) {
                                      typeof(wself) sself = wself;
                                      if (!sself) return;
                                      if (error) {
                                          NSLog(@"%@", error.description);
                                          return;
                                      }
                                      
                                      sself.album.gphoto.access = newAccess;
                                      sself.album.link = link;
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                          
                                          sself.selectedIndex = indexPath.row;
                                          [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
                                      });
                                      
                                      if (sself.changedAlbumBlock) {
                                          sself.changedAlbumBlock(newAccess, link);
                                      }
                                      
                                      NSLog(@"Success!");
                                  }];
    }
    else {
        if (indexPath.row == 1) {
            NSString *link = nil;
            if (![_album.gphoto.access isEqualToString:kPWPicasaAPIGphotoAccessProtected]) {
                for (PWPhotoLinkObject *linkObject in _album.link) {
                    if ([linkObject.rel isEqualToString:kPWPicasaAPILinkRelShare]) {
                        link = linkObject.href;
                    }
                }
            }
            if (link) {
                NSURL *url = [NSURL URLWithString:link];
                UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[_album.title, url] applicationActivities:nil];
                [self.navigationController presentViewController:viewController animated:YES completion:nil];
            }
            
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark AccessLocalizedString
- (NSArray *)arrayOfAccess {
    static dispatch_once_t onceToken;
    static id array;
    dispatch_once(&onceToken, ^{
        array = @[kPWPicasaAPIGphotoAccessPublic, kPWPicasaAPIGphotoAccessPrivate, kPWPicasaAPIGphotoAccessProtected];
    });
    return array;
}

- (NSDictionary *)dictionaryOfAccessDesplayString {
    static dispatch_once_t onceToken;
    static id dictionary;
    dispatch_once(&onceToken, ^{
        dictionary = @{kPWPicasaAPIGphotoAccessPublic: NSLocalizedString(@"すべての人に公開", nil), kPWPicasaAPIGphotoAccessPrivate: NSLocalizedString(@"リンクを知っている人のみ公開", nil), kPWPicasaAPIGphotoAccessProtected: NSLocalizedString(@"非公開", nil)};
    });
    return dictionary;
}

@end
