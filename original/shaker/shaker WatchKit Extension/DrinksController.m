//
//  DrinksController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/6/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "DrinksController.h"
#import "DrinkRowController.h"
#import "CoctailsDatabase.h"
#import "utils.h"

#define SHOW_ROWS_COINT 25

@interface DrinksController ()

@property (nonatomic, weak) IBOutlet WKInterfaceTable * table;
@property (nonatomic, weak) IBOutlet WKInterfaceButton * showmore;

@property (nonatomic, strong ) CoctailsDatabase * database;
@property (nonatomic) NSInteger type;
@property (nonatomic, strong) NSArray *  list;

@end

@implementation DrinksController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.database = nil;
        self.type = 0;
        [self.showmore setHidden:YES];
        [self loadTableData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:@"messageReceived" object:nil];
    }
    return self;
}

- (void) dealloc
{
    self.database = nil;
    self.list = nil;
}

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    NSDictionary * dict = (NSDictionary *)context;
    
    self.type = [[dict objectForKey:@"type"] integerValue];
    self.database = (CoctailsDatabase *)[dict objectForKey:@"database"];
    [self reloadData:YES];
}

- (void) messageReceived:(NSNotification *)notification
{
    [self reloadData:YES];
}

- (void) reloadData:(BOOL)force
{
    NSUserDefaults * def = [utils shakerGroupUserDefaults];
    if ( (! force) && (![def boolForKey:(self.type==0) ? kShakerRecipeUnlocked : kShakerRecordChanged]) )
        return;
    
    [def setBool:NO forKey:(self.type==0) ? kShakerRecipeUnlocked : kShakerRecordChanged];
    [def synchronize];
    self.list = [self.database getFavorites:(self.type==1) all:(self.type==0) isAlcogol:YES];
    [self loadTableData];
//    dispatch_queue_t q_default;
//    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async( q_default, ^(void)
//       {
//           @synchronized( self )
//           {
//               @autoreleasepool
//               {
//                   // search in the background thread
//                   NSArray * lst = [self.database getFavorites:(self.type==1) all:(self.type==0) isAlcogol:YES];
//                   dispatch_queue_t q_main = dispatch_get_main_queue();
//                   dispatch_sync(q_main, ^(void)
//                     {
//                         self.list = lst;
//                         [self loadTableData];
//                     });
//               }
//           }
//       });
}

- (IBAction) loadMoreRows:(id)sender
{
    NSInteger row = [self.table numberOfRows];
    NSInteger count = row;
    if ( row < [self.list count] )
    {
        count = count + SHOW_ROWS_COINT;
        count = MIN( count, [self.list count] );
        NSIndexSet * rows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, count-row)];
        [self.table insertRowsAtIndexes:rows withRowType:@"drink"];
        
        for ( NSInteger idx = row; idx < count; idx++ )
        {
            NSDictionary * info = self.list[idx];
            [self setRowData:info forIndex:idx];
        }
    }
    [self.showmore setHidden:(count >= [self.list count])];
}

- (void) setRowData:(NSDictionary *)info forIndex:(NSInteger)idx
{
    DrinkRowController * row = [self.table rowControllerAtIndex:idx];
    row.tag = (NSInteger)[[info objectForKey:@"id"] longLongValue];
    [row.name setText:[info objectForKey:@"name"]];
    
    NSString * str = @"";
    if ( self.type == 0 )
    {
        str = [info objectForKey:@"shopping"];
    }
    else
    {
        for ( int i = 0; i < [[info objectForKey:@"rating"] intValue]; i++ )
        {
            str = [str stringByAppendingString:@"⭐️"];
        }
    }
    [row.rate setText:str];
}

- (void) loadTableData
{
    if ( self.list != nil && [self.list count] < 1 )
    {
        [self.table setNumberOfRows:1 withRowType:@"drink"];
        DrinkRowController * row = [self.table rowControllerAtIndex:0];
        switch (self.type)
        {
            case 0 :
                [row.name setText:LOC( @"Play Shaker" )];
                break;
                
            case 1 :
            case 2 :
                [row.name setText:LOC( @"No Ratings" )];
                break;
                
            default:
                break;
        }
        [row.rate setText:LOC( @"" )];
        return;
    }
    else if ( self.list == nil )
    {
        [self.table setNumberOfRows:1 withRowType:@"drink"];
        DrinkRowController * row = [self.table rowControllerAtIndex:0];
        [row.name setText:LOC( @"Loading..." )];
        [row.rate setText:LOC( @"" )];
        return;
    }
    
    NSInteger count = MIN( [self.list count], SHOW_ROWS_COINT );
    [self.table setNumberOfRows:count withRowType:@"drink"];
    
    [self.showmore setHidden:(count >= [self.list count])];

    // Create all of the table rows.
    [self.list enumerateObjectsUsingBlock:^(NSDictionary * info, NSUInteger idx, BOOL *stop)
    {
        if ( idx >= count )
        {
            *stop = YES;
            return;
        }
        [self setRowData:info forIndex:idx];
    }];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if ( self.database == nil || rowIndex >= [self.list count] )
        return;
    NSDictionary * info = self.list[rowIndex];
    NSInteger rec_id = (NSInteger)[[info objectForKey:@"id"] longLongValue];
    if ( rec_id > 0 )
    {
        [self pushControllerWithName:@"recipe" context:@{ @"database" : self.database,
                                                          @"id" : [NSNumber numberWithInteger:rec_id] }];
    }
}

- (void)willActivate
{
    [super willActivate];
    [self reloadData:NO];
}

@end
