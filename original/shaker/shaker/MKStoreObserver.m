//
//  MKStoreObserver.m
//
//  Created by Mugunth Kumar on 17-Oct-09.
//  Copyright 2009 Mugunth Kumar. All rights reserved.
//

#import "MKStoreObserver.h"
#import "MKStoreManager.h"

@implementation MKStoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for ( SKPaymentTransaction *transaction in transactions )
	{
		switch (transaction.transactionState)
		{
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

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog( @"%@", queue.transactions );
    
	[[MKStoreManager sharedManager]  restoreTransactionsCompleted:queue.transactions withError:error];
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	NSLog( @"%@", queue.transactions );
	
	[[MKStoreManager sharedManager] restoreTransactionsCompleted:queue.transactions withError:nil];
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
    if ( transaction.error == nil || transaction.error.code == SKErrorPaymentCancelled )
        [[MKStoreManager sharedManager] transactionCanceled:transaction];
    else
        [[MKStoreManager sharedManager] failedTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
	
    [[MKStoreManager sharedManager] provideContent:transaction.payment.productIdentifier
											  forReceipt:[[NSBundle mainBundle] appStoreReceiptURL] isNew:YES];
	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction:(SKPaymentTransaction *)transaction
{
    [[MKStoreManager sharedManager] provideContent: transaction.originalTransaction.payment.productIdentifier
											  forReceipt:[[NSBundle mainBundle] appStoreReceiptURL] isNew:NO];
	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

@end

