//
//  KKStaticTableView.h
//  CommeTube
//
//  Created by Keisuke Karijuku on 2013/11/20.
//  Copyright (c) 2013年 IRIE JUNYA. All rights reserved.
//

@import UIKit;

typedef enum _KKStaticTableViewCellType {
    KKStaticTableViewCellTypeDefault,
    KKStaticTableViewCellTypeSubTitle,
    KKStaticTableViewCellTypeValue1,
    KKStaticTableViewCellTypeCustom
} KKStaticTableViewCellType;

@class KKStaticTableViewSectionItem, KKStaticTableViewRowItem;

@interface KKStaticTableView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic, readonly) NSMutableArray *sections;

@property (strong, nonatomic) UIColor *cellTextColor;
@property (strong, nonatomic) UIFont *cellTextFont;
@property (strong, nonatomic) UIColor *cellDetailTextColor;
@property (strong, nonatomic) UIFont *cellDetailTextFontTypeSubTitle;
@property (strong, nonatomic) UIFont *cellDetailTextFontTypeValue1;

- (KKStaticTableViewSectionItem *)addSectionWithTitle:(NSString *)sectionTitle;

- (KKStaticTableViewSectionItem *)addSectionWithTitle:(NSString *)sectionTitle description:(NSString *)description;


- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle
                                  cellTitle:(NSString *)cellTitle
                                  didSelect:(void (^)())didSelectCellAction;

- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle
                             staticCellType:(KKStaticTableViewCellType)cellType
                                       cell:(void (^)(UITableViewCell *cell, NSIndexPath *indexPath))customCell
                                 cellHeight:(CGFloat)cellHeight
                                     didSelect:(void (^)())didSelectCellAction;

- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle
                            customCellClass:(id)customCellClass
                                       cell:(void (^)(UITableViewCell *cell, NSIndexPath *indexPath))customCell
                                 cellHeight:(CGFloat)cellHeight
                                     didSelect:(void (^)())didSelectCellAction;

- (void)reloadSection:(KKStaticTableViewSectionItem *)staticSection;
- (void)reloadSectionWithTitle:(NSString *)sectionTitle;
- (void)reloadCell:(KKStaticTableViewRowItem *)staticCell;

- (void)removeSection:(KKStaticTableViewSectionItem *)staticSection;
- (void)removeCell:(KKStaticTableViewRowItem *)staticCell;

@end


@interface KKStaticTableViewSectionItem : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *detail;
@property (strong, nonatomic) NSMutableArray *cells;

@end

@interface KKStaticTableViewRowItem : NSObject

@property (nonatomic) KKStaticTableViewCellType type;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *subTitle;
@property (copy, nonatomic) void (^customCell)(UITableViewCell *cell, NSIndexPath *indexPath);
@property (nonatomic) CGFloat customCellHeight;
@property (copy, nonatomic) void (^didSelectCellAction)();
@property (strong, nonatomic) id customCellClass;

@end
