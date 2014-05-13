//
//  PWDatePickerView.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWDatePickerView : UIView

- (id)initWithDate:(NSDate *)date;

@property (strong, nonatomic) void (^doneBlock)(UIView *datePickerView, NSDate *date);
@property (strong, nonatomic) void (^cancelBlock)(UIView *datePickerView);

@end
