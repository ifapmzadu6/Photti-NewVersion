
//  AppPurchase.h
//  Pixiver
//
//  Created by nagatashin on 2013/11/19.
//  Copyright (c) 2013年 Shin NAGATA. All rights reserved.
//

@import Foundation;
@import StoreKit;
@import Security;

@protocol PAInAppPurchaseDelegate <NSObject>

@optional
- (void)inAppPurchaseDidPaymentQueuePurchaced:(NSArray *)transactions success:(BOOL)success;
- (void)inAppPurchaseDidPaymentQueueRestored:(NSArray *)transactions success:(BOOL)success;
- (void)inAppPurchaseDidPaymentQueueTransactionFinishd;

@end

static NSString * const kPDRemoveAdsPuroductID = @"*";

@interface PAInAppPurchase : NSObject

+ (PAInAppPurchase *)sharedInstance;

- (void)addInAppPurchaseObserver:(NSObject *)observer;
- (void)removeInAppPurchaseObserver:(NSObject *)observer;

+ (void)getProductsWithProductIDs:(NSArray *)productIDs completion:(void (^)(NSArray *products, NSError *error))completion;
+ (bool)isPurchasedWithProduct:(SKProduct *)product;
+ (bool)isPurchasedWithKey:(NSString *)key;

//DEBUG
+ (void)resetKeyChain;

@end
