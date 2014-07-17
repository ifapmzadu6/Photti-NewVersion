//
//  PDTaskTableViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PDTaskObject;

@interface PDTaskTableViewCell : UITableViewCell

@property (strong, nonatomic) PDTaskObject *taskObject;
@property (nonatomic) BOOL isNowLoading;

+ (CGFloat)cellHeightForTaskObject:(PDTaskObject *)taskObject;

@end
