//
//  PWImagePickerController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@interface PWImagePickerController : UITabBarController <UITabBarControllerDelegate>

@property (strong, nonatomic) NSArray *selectedPhotoIDs;

- (id)initWithAlbumTitle:(NSString *)albumTitle completion:(void (^)(NSArray *selectedPhotos))completion;

- (void)addSelectedPhoto:(id)photo;
- (void)removeSelectedPhoto:(id)photo;

- (void)doneBarButtonAction;

- (UIEdgeInsets)viewInsets;

@end
