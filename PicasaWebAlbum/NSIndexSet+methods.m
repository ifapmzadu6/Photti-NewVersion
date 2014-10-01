//
//  NSIndexSet+methods.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/10/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "NSIndexSet+methods.h"

@implementation NSIndexSet (methods)

- (NSArray *)indexPathsForSection:(NSUInteger)section {
    NSMutableArray *indexPaths = @[].mutableCopy;
    
    if (self.count > 0) {
        NSUInteger index = self.firstIndex;
        NSUInteger lastIndex = self.lastIndex;
        while (YES) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            [indexPaths addObject:indexPath];
            
            if (index == lastIndex) {
                break;
            }
            index = [self indexGreaterThanIndex:index];
        }
    }
    
    return indexPaths;
}

@end
