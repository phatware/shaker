//
//  MKStoreManager.m
//
//  Created by Mugunth Kumar on 17-Oct-09.
//  Copyright 2009 Mugunth Kumar. All rights reserved.
//  mugunthkumar.com
//

#import "MKStoreManager.h"
#import "utils.h"

@interface MKStoreManager ()
{
    BOOL requestingData;
    BOOL canPurchaseAds;
    BOOL canPurchaseList;
}

@end

@implementation MKStoreManager

@synthesize purchasableObjects;
@synthesize storeObserver;
@synthesize delegate;

// all your features should be managed one and only by StoreManager
static NSString *featureDisableAds = @"com.phunkware.shaker.adbanner";
static NSString *featureUnlockAll = @"com.phunkware.shaker.unlockall";
static BOOL featureDisableAdsPurchased = YES;
static BOOL featureUnlockAllPurchased = YES;
static MKStoreManager *  _sharedStoreManager = nil;


+ (void) off
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:NO forKey:featureDisableAds];
}

+ (MKStoreManager *)sharedManager
{
	@synchronized(self)
    {
        if (_sharedStoreManager == nil)
        {
            _sharedStoreManager = [[MKStoreManager alloc] init]; // assignment not done here
        }
    }
    return _sharedStoreManager;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		requestingData = NO;
        canPurchaseAds = NO;
        canPurchaseList = NO;
        // TODO: unlock all recepies
        // featureDisableAdsPurchased = NO;
        // featureUnlockAllPurchased = NO;
		self.delegate = nil;
        
        self.purchasableObjects = [[NSMutableArray alloc] init];
        
        [MKStoreManager loadPurchases];
        self.storeObserver = [[MKStoreObserver alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self.storeObserver];
		[self requestProductData];
	}
	return self;
}


- (void)dealloc
{
    self.purchasableObjects = nil;
}

- (BOOL) isBusy
{
	return requestingData;
}

- (BOOL) canPruchaseDisableAds
{
    return canPurchaseAds;
}

- (BOOL) canPruchaseUnlockAll
{
    return canPurchaseList;
}

- (void) requestProductData
{
    if ( [self isBusy] )
        return;
	SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:
								 [NSSet setWithObjects: featureDisableAds, featureUnlockAll, nil]]; // add any other product here
	request.delegate = self;
    requestingData = YES;
    canPurchaseAds = NO;
    canPurchaseList = NO;
	[request start];
}


- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	[purchasableObjects addObjectsFromArray:response.products];
	// populate your UI Controls here
	for ( int i = 0; i < [purchasableObjects count]; i++ )
	{
		SKProduct *product = [purchasableObjects objectAtIndex:i];
		NSLog(@"Feature: %@, Cost: %f, ID: %@",[product localizedTitle],
			  [[product price] doubleValue], [product productIdentifier]);
        
        if ( [product.productIdentifier isEqualToString:featureDisableAds] )
            canPurchaseAds = YES;
        if ( [product.productIdentifier isEqualToString:featureUnlockAll] )
            canPurchaseList = YES;
	}
	
	requestingData = NO;
	if(delegate && [delegate respondsToSelector:@selector(productFetchComplete:)])
	{
		[delegate productFetchComplete:self];
	}
}

- (void) buyFeatureDisableAds
{
	[self buyFeature:featureDisableAds];
}

- (void) buyFeatureUnlockAll
{
    [self buyFeature:featureUnlockAll];
}

- (void) buyFeature:(NSString*) featureId
{
    if ( [self isBusy] )
        return;
	if ([SKPaymentQueue canMakePayments])
	{
        for ( int i = 0; i < [self.purchasableObjects count]; i++ )
        {
            SKProduct * product = [self.purchasableObjects objectAtIndex:i];
            if ( [featureId caseInsensitiveCompare:product.productIdentifier] == NSOrderedSame )
            {
                SKPayment *payment = [SKPayment paymentWithProduct:product];
                [[SKPaymentQueue defaultQueue] addPayment:payment];
                requestingData = YES;
                return;
            }
        }
        [utils showUserMessage:LOC( @"This product is currently unavailable, please try again later." ) withTitle:LOC( @"AppStore Error")];
	}
	else
	{
        [utils showUserMessage:LOC( @"Check your AppStore settings and try again." ) withTitle:LOC( @"AppStore Disabled")];
	}
}

- (void) restorePreviousTransactions
{
    if ( [self isBusy] )
        return;
	if ( [SKPaymentQueue canMakePayments] )
	{
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
		requestingData = YES;
	}
	else
	{
        [utils showUserMessage:LOC( @"Check your AppStore settings and try again." ) withTitle:LOC( @"AppStore Disabled")];
	}
}


- (void) restoreTransactionsCompleted:(NSArray *)transactions withError:(NSError *)error
{
	requestingData = NO;
	if ( error == nil )
	{
        for ( SKPaymentTransaction * transaction in transactions )
        {
            // TODO: this needs to be fixed for restore...
            if ( [transaction.payment.productIdentifier isEqualToString:featureDisableAds] )
            {
                if ( !featureDisableAdsPurchased )
                {
                    continue;
                    // [self buyFeatureDisableAds];
                    // return;
                }
            }
            else if ( [transaction.payment.productIdentifier isEqualToString:featureUnlockAll] )
            {
                if ( !featureUnlockAllPurchased )
                {
                    continue;
                    // [self buyFeatureUnlockAll];
                    // return;
                }
            }
            if ( delegate && [delegate respondsToSelector:@selector(productPurchased:storeManager:)])
            {
                [delegate productPurchased:transaction.payment.productIdentifier storeManager:self];
            }
        }
        if ( delegate && [delegate respondsToSelector:@selector(transactionsRestored:)])
        {
            [delegate transactionsRestored:self];
        }
	}
	else if ( error != nil )
	{
        [utils showUserMessage:[error localizedDescription] withTitle:LOC( @"AppStore Error")];
	}
}

- (void) transactionCanceled: (SKPaymentTransaction *)transaction
{
	NSLog(@"User cancelled transaction: %@", [transaction description]);
	
	requestingData = NO;
	if(delegate && [delegate respondsToSelector:@selector(transactionCanceled:)])
	{
		[delegate transactionCanceled:self];
	}
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
	requestingData = NO;
    [utils showUserMessage:[transaction.error localizedRecoverySuggestion] withTitle:[transaction.error localizedFailureReason]];
}

- (void) provideContent:(NSString*)productIdentifier forReceipt:(NSURL *) receiptData isNew:(BOOL)newTransaction
{
    requestingData = NO;
    if ( [productIdentifier isEqualToString:featureDisableAds] )
    {
        // automatically enable English, if medical pack is purchased & restored
        
        [MKStoreManager updateDisableAdsPurchase];
        if ( delegate && [delegate respondsToSelector:@selector(productPurchased:storeManager:)])
        {
            [delegate productPurchased:productIdentifier storeManager:self];
        }
    }
    if ( [productIdentifier isEqualToString:featureUnlockAll] )
    {
        // automatically enable English, if medical pack is purchased & restored
        
        [MKStoreManager updateUnlockAllPurchase];
        if ( delegate && [delegate respondsToSelector:@selector(productPurchased:storeManager:)])
        {
            [delegate productPurchased:productIdentifier storeManager:self];
        }
    }
    
    if ( ! newTransaction )
    {
        NSLog( @"The '%@' has been already purchased.", productIdentifier );
    }
}


- (void) provideContent: (NSString*) productIdentifier
{
    requestingData = NO;
	if ( [productIdentifier isEqualToString:featureDisableAds] )
	{
        [MKStoreManager updateDisableAdsPurchase];
        if ( delegate && [delegate respondsToSelector:@selector(productPurchased:storeManager:)])
        {
            [delegate productPurchased:productIdentifier storeManager:self];
        }
	}
    if ( [productIdentifier isEqualToString:featureUnlockAll] )
    {
        [MKStoreManager updateUnlockAllPurchase];
        if ( delegate && [delegate respondsToSelector:@selector(productPurchased:storeManager:)])
        {
            [delegate productPurchased:productIdentifier storeManager:self];
        }
    }
}

+ (void) loadPurchases
{
	// NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	// featureDisableAdsPurchased = [userDefaults boolForKey:featureDisableAds];
    // featureUnlockAllPurchased = [userDefaults boolForKey:featureUnlockAll];
}

+ (void) updateDisableAdsPurchase
{
    featureDisableAdsPurchased = YES;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:featureDisableAdsPurchased forKey:featureDisableAds];
}

+ (void) updateUnlockAllPurchase
{
    featureUnlockAllPurchased = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:featureUnlockAllPurchased forKey:featureUnlockAll];
}

+ (BOOL) featureDisableAdsPurchased
{
    [MKStoreManager loadPurchases];
	return featureDisableAdsPurchased;
}

+ (BOOL) featureUnlockAllPurchased
{
    [MKStoreManager loadPurchases];
    return featureUnlockAllPurchased;
}

+ (NSString *) featureUnlockAllID
{
    return featureUnlockAll;
}

@end
