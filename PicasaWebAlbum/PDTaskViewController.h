//
//  PDTaskViewController.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseViewController.h"

@class PDTaskObject;

@interface PDTaskViewController : PABaseViewController

@property (nonatomic, readonly) PDTaskObject *taskObject;

- (instancetype)initWithTaskObject:(PDTaskObject *)taskObject;

@end
