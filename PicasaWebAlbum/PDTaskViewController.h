//
//  PWTaskViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

@class PDTaskObject;

@interface PDTaskViewController : UIViewController

- (id)initWithTask:(PDTaskObject *)taskObject;

@end
