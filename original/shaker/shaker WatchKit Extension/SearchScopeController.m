//
//  SearchScopeController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/7/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "SearchScopeController.h"
#import "MainRowController.h"
#import "utils.h"

@interface SearchScopeController ()

@property (nonatomic, weak) IBOutlet WKInterfaceTable * table;
@property (nonatomic, weak) id<SearchScopeProtocol> delegate;

@end

@implementation SearchScopeController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)loadTableData
{
    [self.table setNumberOfRows:3 withRowType:@"main"];
    
    MainRowController * row = [self.table rowControllerAtIndex:0];
    [row.label setText:LOC( @"Titles" )];
    [row.image setImageNamed:@"titles"];
    
    row = [self.table rowControllerAtIndex:1];
    [row.label setText:LOC( @"Ingredients" )];
    [row.image setImageNamed:@"ingredients"];
    
    row = [self.table rowControllerAtIndex:2];
    [row.label setText:LOC( @"Instructions" )];
    [row.image setImageNamed:@"instructions"];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(searchScopeSelected:)] )
    {
        [self.delegate searchScopeSelected:(SearchScopeType)rowIndex];
    }
    [self popController];
}

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    self.delegate = context;
    
    [self loadTableData];
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


