#import "FlashRuntimeExtensions.h"
#import "ZengIAPHelper.h"

NSArray *_products;
ZengIAPHelper *_iapHelper;

FREObject helloWorld(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
    NSLog(@"Hello World Method!");
    NSString *helloStr = @"Hello World!";
    
    //convert Objective-C string to C utf8 string
    const char *str = [helloStr UTF8String];
    
    //prepare for AS3
    FREObject retStr;
    FRENewObjectFromUTF8((uint8_t)(strlen(str) + 1), (const uint8_t*)str, &retStr);
    return retStr;
}
/**
 init 
 + argv[0] : một Vector gồm các chuỗi productId của item trong In-App Purchase
 */
FREObject init(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
    FREObject vec = argv[0]; //vector
    uint32_t vecLen;
    FREGetArrayLength(vec, &vecLen);
    
    NSMutableSet *pids = [NSMutableSet set];
    
    int32_t i = 0;
    for (i=0;i<vecLen;i++) {
        FREObject element;
        FREGetArrayElementAt(vec, i, &element);
        
        uint32_t elementStringLenght;
        const uint8_t *elementString;
        FREGetObjectAsUTF8(element, &elementStringLenght, &elementString);
        
        //convert C String to Objective-C String
        NSString *str = [NSString stringWithUTF8String:(char *)elementString];
        [pids addObject:str];
    }
    
    _iapHelper = [[ZengIAPHelper alloc] init];
    [_iapHelper setContext:ctx];
    
    [_iapHelper addProductIdentifiers:pids];
    [_iapHelper requestProductWithCompletionHandler:^(BOOL success, NSArray *products) {
        const uint8_t *code ;
        const uint8_t *level;
        if (success) {
            _products = products;
            //dispatch-event
            code = (const uint8_t *)[[NSString stringWithFormat:@"ZSKGetProducts"] UTF8String];
            level = (const uint8_t *)[[NSString stringWithFormat:@"Success"] UTF8String];
            
        } else {
            //dispatch-event
            code = (const uint8_t *)[[NSString stringWithFormat:@"ZSKGetProducts"] UTF8String];
            level = (const uint8_t *)[[NSString stringWithFormat:@"Fail"] UTF8String];
        }
        FREDispatchStatusEventAsync(ctx, code , level);
    }];
    
    return NULL;
}

/**
 [String] argv[0]: product indentifier
 */
FREObject buyProduct(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
    FREObject pidObj = argv[0];
    uint32_t pidStringLen;
    const uint8_t *pidString;
    
    FREGetObjectAsUTF8(pidObj, &pidStringLen, &pidString);
    
    //convert to Objective-C String
    NSString *pid = [NSString stringWithUTF8String:(char *)pidString];
    for (SKProduct *product in _products) {
        if ([product.productIdentifier isEqualToString:pid]) {
            [_iapHelper buyProduct:product];
        }
    }
    
    return NULL;
}

/**
 (String) argv[0]: product identifier
 */
FREObject productPurchased(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    FREObject pidObj = argv[0];
    uint32_t stringLen;
    const uint8_t *pidString;
    FREGetObjectAsUTF8(pidObj, &stringLen, &pidString);
    
    NSString *pid = [NSString stringWithUTF8String:(char *)pidString];
    pid = nil;
    BOOL right = [_iapHelper productPurchased:pid];
    
    FREObject ret = nil;
    FRENewObjectFromBool(right, &ret);
    
    return ret;
}

FREObject restoreCompletedTransactions(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [_iapHelper restoreCompletedTransactions];
    return NULL;
}

#pragma mark Context
void ZengStoreKitContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
    //we expose two methods to ActionScript
	*numFunctionsToTest = 4;
    
	FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * 4);
    
	func[0].name = (const uint8_t*) "init";
	func[0].functionData = NULL;
    func[0].function = &init;
    
    func[1].name = (const uint8_t*) "buyProduct";
	func[1].functionData = NULL;
    func[1].function = &buyProduct;
    
    func[2].name = (const uint8_t*) "productPurchased";
	func[2].functionData = NULL;
    func[2].function = &productPurchased;
    
    func[3].name = (const uint8_t*) "restoreCompletedTransactions";
	func[3].functionData = NULL;
    func[3].function = &restoreCompletedTransactions;
    
	*functionsToSet = func;
}

void ZengStoreKitContextFinalizer(FREContext ctx) {
    
    [_iapHelper setContext:NULL];
    _iapHelper = nil;
    
    _products = nil;
    
    return;
}

#pragma mark Extension Context
void ZengStoreKitExtInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &ZengStoreKitContextInitializer;
    *ctxFinalizerToSet = &ZengStoreKitContextFinalizer;
}

void ZengStoreKitExtFinalizer(void *extData) {
    return;
}


