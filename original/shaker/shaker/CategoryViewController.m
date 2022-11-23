//
//  CategoryViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/25/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "CategoryViewController.h"
#import "IngredientsViewController.h"
#import "utils.h"

static NSString * kCellIdentifier = @"CELL_ID_23i479246703";

@interface CategoryViewController ()

@property (nonatomic, strong) NSArray * categories;

@end

@implementation CategoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.categories = [self.database inredientsCategories];
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithTitle:LOC( @"Play!" ) style:(UIBarButtonItemStyleDone) target:self action:@selector(start:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    self.title = LOC( @"Ingredients" );
    
    NSArray* toolbarItems = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc] initWithTitle:LOC( @"Reset Ingredients" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(resetAll:)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithTitle:LOC( @"Enable All Ingredients" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(enableAll:)],
                             nil];
    self.toolbarItems = toolbarItems;
    self.navigationController.toolbarHidden = NO;
}

- (void) resetAll:(id)sender
{
    // disable all ingredients
    [self.database enableAllIngredients:NO];
}

- (void) enableAll:(id)sender
{
    // disable all ingredients
    [self.database enableAllIngredients:YES];
}

- (void) cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void) start:(id)sender
{
    if ([self.database countEnabledIngradients:YES] < 2)
    {
        // error, no ingredients selected
        [utils showUserMessage:LOC(@"") withTitle:LOC(@"Please select 2 or more ingredients")];
        return;
    }
        
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if ( self.delegate && [self.delegate respondsToSelector:@selector(categoryViewControllerPlayPressed)])
        {
            [self.delegate categoryViewControllerPlayPressed];
        }
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if ( row >= [self.categories count] )
    {
        cell.textLabel.text = @"";
    }
    else
    {
        cell.textLabel.text = [[self.categories objectAtIndex:row] objectForKey:@"category"];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    
    if ( row < [self.categories count] )
    {
        sqlite3_int64  category_id = [[[self.categories objectAtIndex:row] objectForKey:@"id"] longLongValue];
        
        IngredientsViewController * ivc = [[IngredientsViewController alloc] initWithStyle:(UITableViewStylePlain)];
        ivc.database = self.database;
        ivc.category_id = category_id;
        [self.navigationController pushViewController:ivc animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}


@end
