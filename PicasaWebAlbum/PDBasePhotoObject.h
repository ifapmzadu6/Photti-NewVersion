//
//  PDBasePhotoObject.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import CoreData;

@class PDTaskObject;

@interface PDBasePhotoObject : NSManagedObject

@property (nonatomic, retain) NSNumber * session_task_identifier;
@property (nonatomic, retain) NSNumber * tag_sort_index;
@property (nonatomic, retain) PDTaskObject *task;

@end
