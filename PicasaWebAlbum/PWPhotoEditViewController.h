//
//  PWPhotoEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/10.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PWPhotoObject;

@interface PWPhotoEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithPhoto:(PWPhotoObject *)photo;

@end
