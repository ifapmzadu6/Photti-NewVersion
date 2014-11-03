//
//  SEImageViewController.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface SEImageViewController : UIViewController

@property (copy, nonatomic) void (^viewDidAppearBlock)();

@property (nonatomic, readonly) NSInteger index;
@property (strong, nonatomic, readonly) NSItemProvider *item;

- (instancetype)initWithIndex:(NSInteger)index item:(NSItemProvider *)item;

@end
