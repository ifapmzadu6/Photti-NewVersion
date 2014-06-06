//
//  PWDatePickerView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWDatePickerView : UIView

- (id)initWithDate:(NSDate *)date;

@property (copy, nonatomic) void (^doneBlock)(UIView *datePickerView, NSDate *date);
@property (copy, nonatomic) void (^cancelBlock)(UIView *datePickerView);

@end
