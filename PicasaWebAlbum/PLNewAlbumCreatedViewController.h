//
//  PLNewAlbumCreatedViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

@interface PLNewAlbumCreatedViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

- (id)initWithEnumuratedDate:(NSDate *)date;

@end
