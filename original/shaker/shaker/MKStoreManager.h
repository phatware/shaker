//
//  StoreManager.h
//  MKSync
//
//  Created by Mugunth Kumar on 17-Oct-09.
//  Copyright 2009 MK Inc. All rights reserved.
//  mugunthkumar.com

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MKStoreObserver.h"

@class MKStoreManager;

@protocol MKStoreKitDelegate <NSObject>

@optional
- (void) productFetchComplete:(MKStoreManager *)storeManager;
- (void) productPurchased:(NSString *)productId storeManager:(MKStoreManager *)storeManager;
- (void) transactionCanceled:(MKStoreManager *)storeManager;
- (void) transactionsRestored:(MKStoreManager *)storeManager;

@end

@interface MKStoreManager : NSObject<SKProductsRequestDelegate>
{

	NSMutableArray *purchasableObjects;
	MKStoreObserver *storeObserver;	

	id<MKStoreKitDelegate> delegate;
}

@property (nonatomic, retain) id<MKStoreKitDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *purchasableObjects;
@property (nonatomic, retain) MKStoreObserver *storeObserver;

- (void) requestProductData;

- (void) buyFeatureDisableAds; // expose product buying functions, do not expose
- (void) buyFeatureUnlockAll;

// do not call this directly. This is like a private method
- (void) buyFeature:(NSString*) featureId;

- (void) transactionCanceled: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) provideContent:(NSString*)productIdentifier forReceipt:(NSURL*) receiptData  isNew:(BOOL)newTransaction;
- (void) restorePreviousTransactions;

- (void) restoreTransactionsCompleted:(NSArray *)transactions withError:(NSError *)error;
- (BOOL) canPruchaseDisableAds;
- (BOOL) canPruchaseUnlockAll;

+ (MKStoreManager*)sharedManager;

+ (BOOL) featureDisableAdsPurchased;
+ (BOOL) featureUnlockAllPurchased;

+ (NSString *) featureUnlockAllID;

+ (void) updateUnlockAllPurchase;
+ (void) updateDisableAdsPurchase;
+ (void) loadPurchases;

@end
