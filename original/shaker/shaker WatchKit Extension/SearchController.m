//
//  SearchController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/7/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "SearchController.h"
#import "CoctailsDatabase.h"
#import "SearchRowController.h"
#import "utils.h"

#define SHOW_ROWS_COINT 25

@interface SearchController ()

@property (nonatomic, weak) IBOutlet WKInterfaceTable * table;
@property (nonatomic, weak) IBOutlet WKInterfaceButton * showmore;

@property (nonatomic, strong) NSString * search_text;
@property (nonatomic, strong) CoctailsDatabase * database;
@property (nonatomic, strong) NSArray * results;
@property (nonatomic, strong) NSString * defstring;

@end

@implementation SearchController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    NSDictionary * dict = (NSDictionary *)context;

    self.search_text = [dict objectForKey:@"text"];
    self.database = (CoctailsDatabase *)[dict objectForKey:@"database"];
        
    [self.showmore setHidden:YES];

    // Configure interface objects here.
    self.defstring = LOC( @"Searching..." );
    [self loadTableData];
    [self performSelector:@selector(searchDatabase) withObject:nil afterDelay:0.2];
}

- (void) dealloc
{
    self.search_text = nil;
    self.database = nil;
    self.results = nil;
    self.defstring = nil;
}

- (void) searchDatabase
{
    if ( self.database != nil )
    {
        dispatch_queue_t q_default;
        q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async( q_default, ^(void)
           {
               @synchronized( self )
               {
                   @autoreleasepool
                   {
                       // search in the background thread
                       NSArray * lst = [self.database getUnlockedRecordList:YES filter:self.search_text addName:YES];
                       dispatch_queue_t q_main = dispatch_get_main_queue();
                       dispatch_sync(q_main, ^(void)
                         {
                             self.defstring = LOC( @"No Matches" );
                             self.results = lst;
                             [self loadTableData];
                         });
                   }
               }
           });
    }
}

- (IBAction) loadMoreRows:(id)sender
{
    NSInteger row = [self.table numberOfRows];
    NSInteger count = row;
    if ( row < [self.results count] )
    {
        count = count + SHOW_ROWS_COINT;
        count = MIN( count, [self.results count] );
        NSIndexSet * rows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, count-row)];
        [self.table insertRowsAtIndexes:rows withRowType:@"result"];
        
        for ( NSInteger idx = row; idx < count; idx++ )
        {
            NSDictionary * info = self.results[idx];
            [self setRowData:info forIndex:idx];
        }
    }
    [self.showmore setHidden:(count >= [self.results count])];
}

- (void) setRowData:(NSDictionary *)info forIndex:(NSInteger)idx
{
    SearchRowController * row = [self.table rowControllerAtIndex:idx];
    row.tag = (NSInteger)[[info objectForKey:@"id"] longLongValue];
    [row.name setText:[info objectForKey:@"name"]];
}

- (void) loadTableData
{
    if ( [self.results count] < 1 )
    {
        [self.table setNumberOfRows:1 withRowType:@"result"];
        SearchRowController * row = [self.table rowControllerAtIndex:0];
        [row.name setText:self.defstring];
        return;
    }
    
    NSInteger count = MIN( [self.results count], SHOW_ROWS_COINT );
    [self.table setNumberOfRows:count withRowType:@"result"];
    
    [self.showmore setHidden:(count >= [self.results count])];
    
    // Create all of the table rows.
    [self.results enumerateObjectsUsingBlock:^(NSDictionary * info, NSUInteger idx, BOOL *stop)
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
    if ( self.database == nil || rowIndex >= [self.results count] )
        return;
    NSDictionary * info = self.results[rowIndex];
    NSInteger rec_id = (NSInteger)[[info objectForKey:@"id"] longLongValue];
    if ( rec_id > 0 )
    {
        [self pushControllerWithName:@"recipe" context:@{ @"database" : self.database,
                                                          @"id" : [NSNumber numberWithInteger:rec_id] }];
    }
}

- (void)willActivate
{
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate
{
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



