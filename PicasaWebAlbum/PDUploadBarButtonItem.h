//
//  PDUploadBarButtonItem.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDUploadBarButtonItem : UIBarButtonItem

@property (nonatomic, readonly) BOOL animated;

- (void)startAnimation;
- (void)endAnimation;

@end
