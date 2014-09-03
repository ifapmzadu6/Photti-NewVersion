//
//  KKStaticTableView.m
//  CommeTube
//
//  Created by Keisuke Karijuku on 2013/11/20.
//  Copyright (c) 2013年 IRIE JUNYA. All rights reserved.
//

#import "KKStaticTableView.h"

@interface KKStaticTableView ()

@end

@implementation KKStaticTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        self.exclusiveTouch = YES;
        
        _sections = @[].mutableCopy;
    }
    return self;
}

- (KKStaticTableViewSectionItem *)addSectionWithTitle:(NSString *)sectionTitle {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            NSLog(@"その名前のセクションが既に存在します。");
            return nil;
        }
    }
    KKStaticTableViewSectionItem *newSection = [[KKStaticTableViewSectionItem alloc] init];
    newSection.title = sectionTitle;
    [_sections addObject:newSection];
    
    return newSection;
}

- (KKStaticTableViewSectionItem *)addSectionWithTitle:(NSString *)sectionTitle description:(NSString *)description {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            NSLog(@"その名前のセクションが既に存在します。");
            return nil;
        }
    }
    KKStaticTableViewSectionItem *newSection = [[KKStaticTableViewSectionItem alloc] init];
    newSection.title = sectionTitle;
    newSection.detail = description;
    [_sections addObject:newSection];
    
    return newSection;
}

- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle cellTitle:(NSString *)cellTitle didSelect:(void (^)())didSelectCellAction {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            KKStaticTableViewRowItem *newStaticCell = [[KKStaticTableViewRowItem alloc] init];
            newStaticCell.type = KKStaticTableViewCellTypeDefault;
            newStaticCell.title = cellTitle;
            newStaticCell.didSelectCellAction = didSelectCellAction;
            [section.cells addObject:newStaticCell];
            return newStaticCell;
        }
    }
    NSLog(@"[Error]その名前のセクションがありません。");
    return nil;
}

- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle
                             staticCellType:(KKStaticTableViewCellType)cellType
                                       cell:(void (^)(UITableViewCell *cell, NSIndexPath *indexPath))customCell
                                 cellHeight:(CGFloat)cellHeight
                                     didSelect:(void (^)())didSelectCellAction {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            KKStaticTableViewRowItem *newStaticCell = [[KKStaticTableViewRowItem alloc] init];
            newStaticCell.type = cellType;
            newStaticCell.customCell = customCell;
            newStaticCell.customCellHeight = cellHeight;
            newStaticCell.didSelectCellAction = didSelectCellAction;
            [section.cells addObject:newStaticCell];
            return newStaticCell;
        }
    }
    NSLog(@"[Error]その名前のセクションがありません。");
    return nil;
}

- (KKStaticTableViewRowItem *)addCellAtSection:(NSString *)sectionTitle
                            customCellClass:(id)customCellClass
                                       cell:(void (^)(UITableViewCell *cell, NSIndexPath *indexPath))customCell
                                 cellHeight:(CGFloat)cellHeight
                                     didSelect:(void (^)())didSelectCellAction {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            KKStaticTableViewRowItem *newStaticCell = [[KKStaticTableViewRowItem alloc] init];
            newStaticCell.type = KKStaticTableViewCellTypeCustom;
            newStaticCell.customCell = customCell;
            newStaticCell.customCellClass = customCellClass;
            newStaticCell.customCellHeight = cellHeight;
            newStaticCell.didSelectCellAction = didSelectCellAction;
            [section.cells addObject:newStaticCell];
            return newStaticCell;
        }
    }
    NSLog(@"[Error]その名前のセクションがありません。");
    return nil;
}

- (void)reloadSection:(KKStaticTableViewSectionItem *)staticSection {
    if ([_sections containsObject:staticSection]) {
        NSInteger indexForSection = [_sections indexOfObject:staticSection];
        [self reloadSections:[NSIndexSet indexSetWithIndex:indexForSection] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)reloadSectionWithTitle:(NSString *)sectionTitle {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.title isEqualToString:sectionTitle]) {
            NSInteger indexForSection = [_sections indexOfObject:section];
            [self reloadSections:[NSIndexSet indexSetWithIndex:indexForSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)reloadCell:(KKStaticTableViewRowItem *)staticCell {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.cells containsObject:staticCell]) {
            NSInteger index = [section.cells indexOfObject:staticCell];
            NSInteger indexForSection = [_sections indexOfObject:section];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:indexForSection];
            [self reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)removeSection:(KKStaticTableViewSectionItem *)staticSection {
    if ([_sections containsObject:staticSection]) {
        [_sections removeObject:staticSection];
        [self reloadData];
    }
}

- (void)removeCell:(KKStaticTableViewRowItem *)staticCell {
    for (KKStaticTableViewSectionItem *section in _sections) {
        if ([section.cells containsObject:staticCell]) {
            [section.cells removeObject:staticCell];
            NSInteger indexForSection = [_sections indexOfObject:section];
            [self reloadSections:[NSIndexSet indexSetWithIndex:indexForSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    KKStaticTableViewSectionItem *staticSection = _sections[section];
    return staticSection.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    KKStaticTableViewSectionItem *staticSection = _sections[section];
    return staticSection.detail;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    KKStaticTableViewSectionItem *staticSection = _sections[section];
    return staticSection.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KKStaticTableViewSectionItem *staticSection = _sections[indexPath.section];
    KKStaticTableViewRowItem *staticCell = staticSection.cells[indexPath.row];
    
    NSString *identifier = NSStringFromClass(staticCell.customCellClass);
    if (staticCell.type != KKStaticTableViewCellTypeCustom) {
        identifier = [NSStringFromClass([UITableViewCell class]) stringByAppendingFormat:@"%d", staticCell.type];
    }
    UITableViewCell *cell = [self dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        if (staticCell.type == KKStaticTableViewCellTypeDefault) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        else if (staticCell.type == KKStaticTableViewCellTypeSubTitle) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        else if (staticCell.type == KKStaticTableViewCellTypeValue1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        }
        else if (staticCell.type == KKStaticTableViewCellTypeCustom) {
            cell = [[staticCell.customCellClass alloc] init];
        }
    }
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    cell.textLabel.textColor = self.cellTextColor;
    cell.textLabel.alpha = 1.0f;
    cell.detailTextLabel.textColor = self.cellDetailTextColor;
    cell.detailTextLabel.alpha = 1.0f;
    cell.textLabel.font = self.cellTextFont;
    if (staticCell.type == KKStaticTableViewCellTypeSubTitle) {
        cell.detailTextLabel.font = self.cellDetailTextFontTypeSubTitle;
    }
    else if (staticCell.type == KKStaticTableViewCellTypeValue1) {
        cell.detailTextLabel.font = self.cellDetailTextFontTypeValue1;
    }
    
    if (staticCell.title) {
        cell.textLabel.text = staticCell.title;
    }
    if (staticCell.subTitle) {
        cell.detailTextLabel.text = staticCell.subTitle;
    }
    if (staticCell.customCell) {
        staticCell.customCell(cell, indexPath);
    }
    
    [cell setNeedsDisplay];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KKStaticTableViewSectionItem *staticSection = _sections[indexPath.section];
    KKStaticTableViewRowItem *cell = staticSection.cells[indexPath.row];
    if (cell.customCellHeight != CGFLOAT_MIN) {
        return cell.customCellHeight;
    }
    
    return 44.0f;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KKStaticTableViewSectionItem *staticSection = _sections[indexPath.section];
    KKStaticTableViewRowItem *cell = staticSection.cells[indexPath.row];
    
    if (cell.didSelectCellAction) {
        cell.didSelectCellAction();
    }
    
    [self deselectRowAtIndexPath:indexPath animated:YES];
}

@end


@implementation KKStaticTableViewSectionItem

- (id)init {
    self = [super init];
    if (self) {
        _cells = @[].mutableCopy;
    }
    return self;
}

@end


@implementation KKStaticTableViewRowItem

- (id)init {
    self = [super init];
    if (self) {
        _customCellHeight = CGFLOAT_MIN;
    }
    return self;
}

@end
