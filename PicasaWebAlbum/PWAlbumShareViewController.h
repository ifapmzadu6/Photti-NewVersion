//
//  PWAlbumShareViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PWPicasaAPI.h"

@interface PWAlbumShareViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (copy, nonatomic) void (^changedAlbumBlock)(NSString *newAccess, NSSet *link);

- (id)initWithAlbum:(PWAlbumObject *)album;

@end
