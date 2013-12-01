//
//  IAPHelper.m
//  KittyDance
//
//  Created by Duong Thach on 4/23/13.
//
//

#import "ZengIAPHelper.h"
//NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

@interface ZengIAPHelper() <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@end

@implementation ZengIAPHelper {
    SKProductsRequest *_productRequest;
    RequestProductCompletionHandler _completionHandler;
    NSSet *_productIdentifiers;
    NSMutableSet *_purchasedProductIdentifiers;
    NSArray *_products;
    
    //for extension
    NSString *_transactionStatusCode;
    NSString *_transactionStatusLevel;
}

-(void)setContext:(FREContext)ctx {
    _ctx = ctx;
}

+(ZengIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static ZengIAPHelper* _sharedInstance;
    dispatch_once(&once,^ {
        _sharedInstance = [[ZengIAPHelper alloc] init];
    });
    
    return _sharedInstance;
}

-(void)addProductIdentifiers:(NSSet *)productIdentifiers {
    _productIdentifiers = productIdentifiers;
    _purchasedProductIdentifiers = [NSMutableSet set];
    NSLog(@"Check offline");
    for (NSString *productIdentifer in _productIdentifiers) {
        BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifer];
        if (productPurchased) {
            [_purchasedProductIdentifiers addObject:productIdentifer];
            NSLog(@"Previously purchased: %@",productIdentifer);
        } else {
            NSLog(@"Not purchased: %@",productIdentifer);
        }
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    self = [super init];
    if (self != nil) {
        _productIdentifiers = productIdentifiers;
        _purchasedProductIdentifiers = [NSMutableSet set];
        NSLog(@"Check offline");        
        for (NSString *productIdentifer in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifer];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifer];
                NSLog(@"Previously purchased: %@",productIdentifer);
            } else {
                NSLog(@"Not purchased: %@",productIdentifer);
            }
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

-(void)requestProductWithCompletionHandler:(RequestProductCompletionHandler)completionHandler {
    _completionHandler = [completionHandler copy];
    
    _productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productRequest.delegate = self;
    [_productRequest start];
}

-(BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}
-(void)buyProduct:(SKProduct *)product {
    NSLog(@"buying %@...",product.productIdentifier);
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


-(void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - SKProductRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"Loaded list of products...");
    _productRequest = nil;
    
    NSArray *skProducts = response.products;
    for (SKProduct *skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    if (_completionHandler)
        _completionHandler(YES,skProducts);
    _completionHandler = nil;
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Failed to load list of products.");
    _productRequest = nil;
    if (_completionHandler)
        _completionHandler(NO,nil);
    _completionHandler = nil;
}

#pragma mark - SKPaymentTransactionObserver
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
//        transaction.
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

-(void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"complete transaction...");
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    //dispatch for AS3
    NSString *code = @"ZSKTransaction";
    NSString *level = @"Complete";
    FREDispatchStatusEventAsync(_ctx, (const uint8_t *)[code UTF8String], (const uint8_t *)[level UTF8String]);
}

-(void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restore transaction...");
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    //dispatch for AS3
    NSString *code = @"ZSKTransaction";
    NSString *level = @"Restore";
    FREDispatchStatusEventAsync(_ctx, (const uint8_t *)[code UTF8String], (const uint8_t *)[level UTF8String]);
}

-(void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"failed transaction...");
    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"transaction error: %@",transaction.error.localizedDescription);
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    //dispatch for AS3
    NSString *code = @"ZSKTransaction";
    NSString *level = @"Fail";
    FREDispatchStatusEventAsync(_ctx, (const uint8_t *)[code UTF8String], (const uint8_t *)[level UTF8String]);
}

-(void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
}



@end
