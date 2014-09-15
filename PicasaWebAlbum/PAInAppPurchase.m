//
//  AppPurchase.m
//  Pixiver
//
//  Created by nagatashin on 2013/11/19.
//  Copyright (c) 2013年 Shin NAGATA. All rights reserved.
//

#import "PAInAppPurchase.h"

#import "SFHFKeychainUtils.h"

static NSString * const kServiceName = @"com.photti.picasawebalbum";
static NSString * const kPasswordsKey = @"com.photti.picasawebalbum.password";

@interface PAInAppPurchase () <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (copy, nonatomic) void (^getProductsCompletionBlock)(NSArray *, NSError *);

@end

@implementation PAInAppPurchase

+ (PAInAppPurchase *)sharedInstance {
    static PAInAppPurchase *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [PAInAppPurchase new];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

+ (void)getProductsWithProductIDs:(NSArray *)productIDs completion:(void (^)(NSArray *, NSError*))completion {
    [PAInAppPurchase sharedInstance].getProductsCompletionBlock = completion;
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIDs]];
    productsRequest.delegate = [PAInAppPurchase sharedInstance];
    [productsRequest start];
}

+ (bool)isPurchasedWithProduct:(SKProduct *)product {
    NSString *key = product.productIdentifier;
    return [PAInAppPurchase isPurchasedWithKey:key];
}

+ (bool)isPurchasedWithKey:(NSString *)key {
    NSError *error = nil;
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:key andServiceName:kServiceName error:&error];
    if(error || !password || password.length == 0) {
        return false;
    }
    return ([password isEqualToString:[PAInAppPurchase hashKey:key]]);
}

+ (NSString *)hashKey:(NSString *)key {
    return [NSString stringWithFormat:@"fk-sdjghguye13:2[r2rwhubwfnbs./.3envds_%@", key];
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BOOL isFinished = NO;
    BOOL isPurchaced = NO;
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:// 何らかのOKを押す前の処理
#ifdef DEBUG
                NSLog(@"SKPaymentTransactionStatePurchasing");
#endif
                break;
            case SKPaymentTransactionStatePurchased:// success : 決済手続き完了処理
#ifdef DEBUG
                NSLog(@"SKPaymentTransactionStatePurchased");
#endif
                isFinished = YES;
                isPurchaced = YES;
                for(SKPaymentTransaction *transaction in queue.transactions) {
                    NSString *key = transaction.payment.productIdentifier;
                    NSString *password = [PAInAppPurchase hashKey:key];
                    NSError *error = nil;
                    [SFHFKeychainUtils storeUsername:key andPassword:password forServiceName:kServiceName updateExisting:YES error:&error];
                }
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://  途中でキャンセルした時orエラー
#ifdef DEBUG
                NSLog(@"SKPaymentTransactionStateFailed");
#endif
                NSLog(@"%@", transaction.error);
                isFinished = YES;
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
#ifdef DEBUG
                NSLog(@"SKPaymentTransactionStateRestored");
#endif
                isFinished = YES;
                [queue finishTransaction:transaction];
                break;
            default:
#ifdef DEBUG
                NSLog(@"default");
#endif
                break;
        }
    }
    
    //トランザクションが何らかの完了をした時
    if (isFinished) {
        //支払いが完了したとき
        if(isPurchaced) {
            if (_paymentQueuePurchaced) {
                _paymentQueuePurchaced(transactions, true);
            }
        }
        else if(!isPurchaced) {
            if (_paymentQueueTransactionFinishd) {
                _paymentQueueTransactionFinishd();
            }
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    //リストアの失敗
    if (_paymentQueueRestored) {
        _paymentQueueRestored(queue.transactions, false);
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for(SKPaymentTransaction *transaction in queue.transactions) {
        NSString *key = transaction.payment.productIdentifier;
        NSString *password = [PAInAppPurchase hashKey:key];
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:key andPassword:password forServiceName:kServiceName updateExisting:YES error:&error];
    }
    
    if (_paymentQueueRestored) {
        _paymentQueueRestored(queue.transactions, true);
    }
    
#ifdef DEBUG
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
#endif
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
#ifdef DEBUG
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"invalid product identifier: %@", identifier);
    }
#endif
    
    if (response.products.count == 0) {
        if (_getProductsCompletionBlock) {
            _getProductsCompletionBlock(nil, [NSError errorWithDomain:@"com.photti.PDInAppPurchase.domain" code:500 userInfo:nil]);
            _getProductsCompletionBlock = nil;
        }
    }
    else {
        if (_getProductsCompletionBlock) {
            _getProductsCompletionBlock(response.products, nil);
            _getProductsCompletionBlock = nil;
        }
    }
}

+ (void)resetKeyChain {
    NSString *key = kPDRemoveAdsPuroductID;
    [SFHFKeychainUtils deleteItemForUsername:key andServiceName:kServiceName error:nil];
}

@end
