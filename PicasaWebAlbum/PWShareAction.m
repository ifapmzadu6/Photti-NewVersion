//
//  PWShareAction.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWShareAction.h"

@implementation PWShareAction

+ (void)showFromViewController:(UIViewController *)viewController {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", @"892657316"]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    [viewController presentViewController:activityViewController animated:YES completion:nil];
}

@end
