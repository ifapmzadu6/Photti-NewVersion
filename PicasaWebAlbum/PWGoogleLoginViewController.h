//
//  PWGoogleLoginViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@interface PWGoogleLoginViewController : PABaseViewController

@property (copy, nonatomic) void (^completion)();
@property (copy, nonatomic) void (^skipAction)();


@end
