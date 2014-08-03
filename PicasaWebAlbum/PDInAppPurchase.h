
//  AppPurchase.h
//  Pixiver
//
//  Created by nagatashin on 2013/11/19.
//  Copyright (c) 2013年 Shin NAGATA. All rights reserved.
//

@import Foundation;
@import StoreKit;
@import Security;

static NSString * const kPDRemoveAdsPuroductID = @"34789274982com.photti.picasawebalbum.uploadanddownload";

@interface PDInAppPurchase : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (copy, nonatomic) void (^paymentQueuePurchaced)(NSArray *transactions, bool success);
@property (copy, nonatomic) void (^paymentQueueRestored)(NSArray *transactions, bool success);
@property (copy, nonatomic) void (^paymentQueueTransactionFinishd)();

+ (PDInAppPurchase *)sharedInstance;

+ (void)getProductsWithProductIDs:(NSArray *)productIDs completion:(void (^)(NSArray *products, NSError *error))completion;
+ (bool)isPurchasedWithProduct:(SKProduct *)product;
+ (bool)isPurchasedWithKey:(NSString *)key;

//DEBUG
+ (void)resetKeyChain;

@end
