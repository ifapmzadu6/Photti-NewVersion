//
//  AppPurchase.m
//  Pixiver
//
//  Created by nagatashin on 2013/11/19.
//  Copyright (c) 2013年 Shin NAGATA. All rights reserved.
//

#import "PDInAppPurchase.h"

#import "SFHFKeychainUtils.h"

static NSString * const kServiceName = @"com.photti.picasawebalbum";
static NSString * const kPasswordsKey = @"com.photti.picasawebalbum.password";

@interface PDInAppPurchase ()

@property (copy, nonatomic) void (^getProductsCompletionBlock)(NSArray *, NSError *);

@end

@implementation PDInAppPurchase

+ (PDInAppPurchase *)sharedInstance {
    static PDInAppPurchase *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [PDInAppPurchase new];
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
    [PDInAppPurchase sharedInstance].getProductsCompletionBlock = completion;
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIDs]];
    productsRequest.delegate = [PDInAppPurchase sharedInstance];
    [productsRequest start];
}

+ (bool)isPurchasedWithProduct:(SKProduct *)product {
    NSString *key = product.productIdentifier;
    return [PDInAppPurchase isPurchasedWithKey:key];
}

+ (bool)isPurchasedWithKey:(NSString *)key {
    NSError *error = nil;
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:key andServiceName:kServiceName error:&error];
    if(error || !password || password.length == 0) {
        return false;
    }
    return ([password isEqualToString:[PDInAppPurchase hashKey:key]]);
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
                NSLog(@"SKPaymentTransactionStatePurchasing");
                break;
            case SKPaymentTransactionStatePurchased:// success : 決済手続き完了処理
                NSLog(@"SKPaymentTransactionStatePurchased");
                isFinished = YES;
                isPurchaced = YES;
                for(SKPaymentTransaction *transaction in queue.transactions) {
                    NSString *key = transaction.payment.productIdentifier;
                    NSString *password = [PDInAppPurchase hashKey:key];
                    NSError *error = nil;
                    [SFHFKeychainUtils storeUsername:key andPassword:password forServiceName:kServiceName updateExisting:YES error:&error];
                }
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://  途中でキャンセルした時orエラー
                NSLog(@"SKPaymentTransactionStateFailed");
                NSLog(@"%@", transaction.error.description);
                isFinished = YES;
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"SKPaymentTransactionStateRestored");
                isFinished = YES;
                [queue finishTransaction:transaction];
                break;
            default:
                NSLog(@"default");
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
        NSString *password = [PDInAppPurchase hashKey:key];
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:key andPassword:password forServiceName:kServiceName updateExisting:YES error:&error];
    }
    
    if (_paymentQueueRestored) {
        _paymentQueueRestored(queue.transactions, true);
    }
    
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"invalid product identifier: %@", identifier);
    }
    
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
    NSString *key = kPDUploadAndDownloadPuroductID;
    [SFHFKeychainUtils deleteItemForUsername:key andServiceName:kServiceName error:nil];
}

@end
