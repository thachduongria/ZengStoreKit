//
//  IAPHelper.h
//  KittyDance
//
//  Created by Duong Thach on 4/23/13.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "FlashRuntimeExtensions.h"

UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;

typedef void (^RequestProductCompletionHandler)(BOOL success, NSArray *products);

@interface ZengIAPHelper : NSObject {
    FREContext _ctx;
}

-(id)initWithProductIdentifiers:(NSSet*)productIdentifiers;

-(void)addProductIdentifiers:(NSSet*)productIdentifiers;
-(void)requestProductWithCompletionHandler:(RequestProductCompletionHandler)completionHandler;
-(void)buyProduct:(SKProduct *)product;
-(BOOL)productPurchased:(NSString *)productIdentifier;
-(void)restoreCompletedTransactions;
-(void)setContext:(FREContext)ctx;
@end
