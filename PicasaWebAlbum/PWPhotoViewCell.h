//
//  PWPhotoViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PWPhotoObject;

@interface PWPhotoViewCell : UICollectionViewCell

@property (strong, nonatomic, readonly) PWPhotoObject *photo;
@property (nonatomic) BOOL isSelectWithCheckMark;

- (void)setPhoto:(PWPhotoObject *)photo isNowLoading:(BOOL)isNowLoading;

@end
