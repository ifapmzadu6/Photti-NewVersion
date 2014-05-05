//
//  PWViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWViewController.h"

#import "PWOAuthManager.h"
#import "PWPicasaAPI.h"
#import "PWPicasaParser.h"
#import "PWCoreDataAPI.h"
#import "XmlReader.h"

@interface PWViewController ()

@end

@implementation PWViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([PWOAuthManager isLogin]) {
        [self test];
    }
    else {
        __weak typeof(self) wself = self;
        [self openLoginViewControllerWithCompletion:^{
            typeof(wself) sself = wself;
            [sself test];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)test {
    [PWPicasaAPI getListOfAlbumsWithCompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error!");
            return;
        }
        NSLog(@"success!");
        
        if (data) {
            NSDictionary *json = [XMLReader dictionaryForXMLData:data error:nil];
            
            [PWCoreDataAPI performBlock:^(NSManagedObjectContext *context) {
                NSArray *albums = [PWPicasaParser parseListOfAlbumFromJson:json context:context];
                
            }];
            
        }
    }];
    
//    [PWPicasaAPI getListOfPhotosInAlbumWithAlbumID:@"6009124921979354113" completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        if (error) {
//            NSLog(@"error!");
//            return;
//        }
//        NSLog(@"success!");
//        
//        if (data) {
//            NSDictionary *status = [XMLReader dictionaryForXMLData:data error:nil];
//            status = status[@"feed"];
////            NSArray *entries = status[@"entry"];
////            NSDictionary *firstEntry = entries[10];
//            NSLog(@"%@", status.description);
//        }
//    }];
    
//    [PWPicasaAPI getTestAccessURL:@"http://redirector.googlevideo.com/videoplayback?id=ed3ac1e5215c320f&itag=37&source=picasa&cmo=sensitive_content%3Dyes&ip=0.0.0.0&ipbits=0&expire=1401701484&sparams=id,itag,source,ip,ipbits,expire&signature=2AA389E2A9D63D145DE0C28D8AF42625CEBB77CE.1F8473DBB62DFD7472D7211F6367467B7BB92E4C&key=lh1" completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        if (error) {
//            NSLog(@"error!");
//            return;
//        }
//        NSLog(@"success!");
//        
////        NSDictionary *status = [XMLReader dictionaryForXMLData:data error:nil];
////        UIImage *image = [UIImage imageWithData:data];
//        
//    }];
}

- (void)openLoginViewControllerWithCompletion:(void (^)())completionBlock {
    UINavigationController *navigationControlelr = [PWOAuthManager loginViewControllerWithCompletionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        
        [viewController dismissViewControllerAnimated:YES completion:completionBlock];
    }];
    [self presentViewController:navigationControlelr animated:YES completion:nil];
}

@end
