//
//  PSNewLocalAlbumListViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalAlbumListViewController.h"

#import "PEAlbumListDataSource.h"

@implementation PSNewLocalAlbumListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.albumListDataSource.isSelectMode = YES;
    }
    return self;
}

@end
