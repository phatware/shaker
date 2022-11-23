//
//  InterfaceController.m
//  shaker WatchKit Extension
//
//  Created by Stanislav Miasnikov on 7/6/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "InterfaceController.h"
#import "MainRowController.h"
#import "CoctailsDatabase.h"
#import "SearchScopeController.h"
#import "utils.h"

@interface InterfaceController()

@property (nonatomic, weak) IBOutlet WKInterfaceTable * table;

@property (nonatomic, strong ) CoctailsDatabase * database;

@end


@implementation InterfaceController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        CoctailsDatabase * database = [[CoctailsDatabase alloc] init];
        if ( ! [database initializeDatabase] )
            database = nil;
        self.database = database;
        [self loadTableData];
    }
    return self;
}

- (void) dealloc
{
    self.database = nil;
}

- (void)loadTableData
{
    [self.table setNumberOfRows:4 withRowType:@"main"];
    int index = 0;

    MainRowController * row = [self.table rowControllerAtIndex:index++];
    [row.label setText:LOC( @"Play" )];
    [row.image setImageNamed:@"play"];
    
    row = [self.table rowControllerAtIndex:index++];
    [row.label setText:LOC( @"Unlocked" )];
    [row.image setImageNamed:@"cocktail"];

    row = [self.table rowControllerAtIndex:index++];
    [row.label setText:LOC( @"Good Drinks" )];
    [row.image setImageNamed:@"thumb_up"];

    row = [self.table rowControllerAtIndex:index++];
    [row.label setText:LOC( @"Bad Drinks" )];
    [row.image setImageNamed:@"thumb_down"];

    row = [self.table rowControllerAtIndex:index++];
    [row.label setText:LOC( @"Search" )];
    [row.image setImageNamed:@"search"];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if ( self.database == nil )
        return;
    if ( rowIndex < 3 )
    {
        self.database.unlocked = NO;
        [self pushControllerWithName:@"drinks" context:@{ @"database" : self.database,
                                                        @"type" : [NSNumber numberWithInteger:rowIndex] }];
    }
    else if ( rowIndex == 3 )
    {
        // TODO: search
        self.database.unlocked = [[utils shakerGroupUserDefaults] boolForKey:kShakerAllRecipesVisible];
        
        [self pushControllerWithName:@"scope" context:self];
    }
}

- (void) searchScopeSelected:(SearchScopeType)scope
{
    [self presentTextInputControllerWithSuggestions:nil
                                   allowedInputMode:WKTextInputModePlain
                                         completion:^(NSArray *results)
     {
         if ( results && results.count > 0 )
         {
             NSString * search_text = results[0];
             search_text = [search_text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
             if ( [search_text length] > 1 )
             {
                 // will not searcxh for single character
                 NSString * column = @"name";
                 switch( scope )
                 {
                     case kSearchScopeIngredients :
                         column = @"ingredients";
                         break;
                         
                     case kSearchScopeInstructions :
                         column = @"instructions";
                         break;
                         
                     case kSearchScopeTtitle :
                     default :
                         break;
                 }
                 NSString * strFilter = [NSString stringWithFormat:@"%@ LIKE '%%%@%%'", column, search_text];
                 [self pushControllerWithName:@"results" context:@{ @"database" : self.database,
                                                                    @"text" : strFilter }];
                 // [self performSelector:@selector(searchText:) withObject:strFilter afterDelay:0.1];
             }
         }
     }];
}

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];

    // Configure interface objects here.
    [self.database sync];
}

- (void)willActivate
{
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self.database sync];
}

- (void)didDeactivate
{
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end
