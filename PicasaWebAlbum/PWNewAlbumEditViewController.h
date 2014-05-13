//
//  PWNewAlbumEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWNewAlbumEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) void (^successBlock)();

@end
