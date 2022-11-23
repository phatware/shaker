//
//  RecipesViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/24/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "RecipesViewController.h"
#import "RecipeViewController.h"
#import "utils.h"
#import "MKStoreManager.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS

static NSString * kCellIdentifier = @"CELL_ID_129074298765832";

@interface RecipesViewController ()
{
    NSInteger _searchScope;
}

@property (nonatomic, strong) NSArray * alcoholic;
@property (nonatomic, strong) NSArray * non_alcoholic;
@property (nonatomic, strong) UITableView  * tableSearch;
@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) NSArray * searcharray1;
@property (nonatomic, strong) NSArray * searcharray2;

@end

@implementation RecipesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.alcoholic = [self.database getUnlockedRecordList:YES filter:nil addName:NO];
    self.non_alcoholic = [self.database getUnlockedRecordList:NO filter:nil addName:NO];

//    dispatch_queue_t q_default;
//    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async( q_default, ^(void)
//    {
//        @synchronized( self )
//        {
//            @autoreleasepool
//            {
//                // search in the background thread
//                NSArray * alc = [self.database getUnlockedRecordList:YES filter:nil addName:NO];
//                NSArray * non_alc = [self.database getUnlockedRecordList:NO filter:nil addName:NO];
//
//                dispatch_queue_t q_main = dispatch_get_main_queue();
//                dispatch_sync(q_main, ^(void)
//                {
//                    self.alcoholic = alc;
//                    self.non_alcoholic = non_alc;
//                    [self.tableView reloadData];
//                });
//            }
//        }
//    });
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    if ( ![MKStoreManager featureUnlockAllPurchased] )
    {
        self.database.unlocked = NO;
        UIBarButtonItem * unlockButton = [[UIBarButtonItem alloc] initWithTitle:LOC( @"Unlock All" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(unlock:)];
        self.navigationItem.rightBarButtonItem = unlockButton;
        
        if ( ![MKStoreManager featureUnlockAllPurchased] )
        {
            [MKStoreManager sharedManager].delegate = self;
            if ( ! [[MKStoreManager sharedManager] canPruchaseUnlockAll] )
            {
                [[MKStoreManager sharedManager] requestProductData];
            }
        }
        self.navigationItem.rightBarButtonItem.enabled = [[MKStoreManager sharedManager] canPruchaseUnlockAll];
    }
    else
    {
        self.database.unlocked = [[utils shakerGroupUserDefaults] boolForKey:kShakerAllRecipesVisible];
        UIBarButtonItem * unlockButton = [[UIBarButtonItem alloc] initWithTitle:(self.database.unlocked) ? LOC(@"Unlocked") : LOC(@"Show All") style:(UIBarButtonItemStylePlain) target:self action:@selector(unlock:)];
        self.navigationItem.rightBarButtonItem = unlockButton;
    }
    
    self.title = LOC(@"Recipes");

    // search support
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    searchResultsController.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableSearch = searchResultsController.tableView;
    self.tableSearch.frame = self.tableView.frame;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.definesPresentationContext = YES;

    _searchScope = [[NSUserDefaults standardUserDefaults] integerForKey:kShakerSearchRecipesScope];
    self.searchController.searchBar.showsScopeBar = NO;
    self.searchController.searchBar.scopeButtonTitles = @[LOC(@"Titles"), LOC(@"Ingredients"), LOC(@"Instructions")];
    self.searchController.searchBar.selectedScopeButtonIndex = _searchScope;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    self.searchController.obscuresBackgroundDuringPresentation = YES;
    
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;

    [self setNeedsStatusBarAppearanceUpdate];
    [self.tableView reloadData];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void) unlock:(id)sender
{
    if ( [MKStoreManager featureUnlockAllPurchased] )
    {
        // already purchased
        self.database.unlocked = !self.database.unlocked;
        [self.navigationItem.rightBarButtonItem setTitle:(self.database.unlocked) ? LOC(@"Unlocked") : LOC(@"Show All")];
        [[utils shakerGroupUserDefaults] setBool:self.database.unlocked forKey:kShakerAllRecipesVisible];
        [[utils shakerGroupUserDefaults] synchronize];
    }
    else
    {
        // TODO: unlock all recipes - add in-app purchase
        // [MKStoreManager updateUnlockAllPurchase];
        // self.database.unlocked = YES;
        // [self.navigationItem.rightBarButtonItem setTitle:LOC( @"Unlocked" )];
        [[MKStoreManager sharedManager] restorePreviousTransactions];
        return;
    }
    
    self.alcoholic = [self.database getUnlockedRecordList:YES filter:nil addName:NO];
    self.non_alcoholic = [self.database getUnlockedRecordList:NO filter:nil addName:NO];
    [self.tableView reloadData];
}

- (void) cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if ( [tableView isEqual:self.tableSearch] )
    {
        if ( section == 0 )
            count = [self.searcharray1 count];
        if ( section == 1 )
            count = [self.searcharray2 count];
        return count;
    }
    if ( section == 0 )
        count = [self.alcoholic count];
    if ( section == 1 )
        count = [self.non_alcoholic count];
    if ( count < 1 )
        count = 1;
    return count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString * title = nil;
    // if ( [tableView isEqual:self.tableSearch] )
    //     title = LOC( @"Filtered beverages" );
    if ( section == 0 )
        title = LOC(@"Alcoholic beverages");
    else if ( section == 1 )
        title = LOC(@"Non alcoholic beverages");
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    UITableViewCell *cell = nil;
    NSDictionary * data = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";

    if ( [tableView isEqual:self.tableSearch] )
    {
        if ( section == 0 && row < [self.searcharray1 count] )
        {
            cell.tag = (NSInteger)[[self.searcharray1 objectAtIndex:row] longLongValue];
            data = [self.database getRecipeName:cell.tag alcohol:YES];
        }
        else if ( section == 1 && row < [self.searcharray2 count] )
        {
            cell.tag = (NSInteger)[[self.searcharray2 objectAtIndex:row] longLongValue];
            data = [self.database getRecipeName:cell.tag alcohol:NO];
        }
    }
    else
    {
        if ( section == 0 && row < [self.alcoholic count] )
        {
            cell.tag = (NSInteger)[[self.alcoholic objectAtIndex:row] longLongValue];
            data = [self.database getRecipeName:cell.tag alcohol:YES];
        }
        else if ( section == 1 && row < [self.non_alcoholic count] )
        {
            cell.tag = (NSInteger)[[self.non_alcoholic objectAtIndex:row] longLongValue];
            data = [self.database getRecipeName:cell.tag alcohol:NO];
        }
    }
        
    if ( data == nil )
    {
        if ( row == 0 )
        {
            cell.textLabel.text = LOC(@"Nothing unlocked yet, play Shaker!");
            cell.textLabel.textColor = self.tableView.tintColor;
        }
        return cell;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = data[@"name"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [data[@"enabled"] boolValue] ? [UIColor blackColor] : [UIColor darkGrayColor];
    cell.detailTextLabel.text = data[@"shopping"];
    // [NSString stringWithFormat:LOC( @"%@ served in %@" ), [data objectForKey:@"category"], [[data objectForKey:@"glass"] lowercaseString]];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    sqlite3_int64  record = 0;
    NSDictionary * recipe = nil;
    
    if ( [tableView isEqual:self.tableSearch] )
    {
        if ( section == 0 && row < [self.searcharray1 count] )
        {
            record = [[self.searcharray1 objectAtIndex:row] longLongValue];
            recipe = [self.database getRecipe:record alcohol:YES noImage:NO];
        }
        else if ( section == 1 && row < [self.searcharray2 count] )
        {
            record = [[self.searcharray2 objectAtIndex:row] longLongValue];
            recipe = [self.database getRecipe:record alcohol:NO noImage:NO];
        }
    }
    else
    {
        if ( section == 0 && row < [self.alcoholic count] )
        {
            record = [[self.alcoholic objectAtIndex:row] longLongValue];
            recipe = [self.database getRecipe:record alcohol:YES noImage:NO];
        }
        else if ( section == 1 && row < [self.non_alcoholic count] )
        {
            record = [[self.non_alcoholic objectAtIndex:row] longLongValue];
            recipe = [self.database getRecipe:record alcohol:NO noImage:NO];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ( recipe != nil )
    {
        // show recipe
        RecipeViewController * rc = [[RecipeViewController alloc] init];
        rc.recipe = recipe;
        rc.database = self.database;
        [self.navigationController pushViewController:rc animated:YES];
    }
}

#pragma mark -- Search

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSLog(@"Scope: %ld", (long)selectedScope);
    _searchScope = selectedScope;
    [[NSUserDefaults standardUserDefaults] setInteger:_searchScope forKey:kShakerSearchRecipesScope];
    [self filterContentForSearchText:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [searchController.searchBar text];
    [self filterContentForSearchText:searchString];
}

- (void)willPresentSearchController:(UISearchController *)searchController
{
    // NSLog( @"didPresentSearchController" );
    self.tableSearch.frame = self.view.bounds;
    self.searchController.searchBar.showsScopeBar = YES;
    [self.searchController.searchBar sizeToFit];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.searchController.searchBar.showsScopeBar = NO;
    [self.searchController.searchBar sizeToFit];
}

- (void) filterContentForSearchText:(NSString*)searchText
{
    if ( [searchText length] < 1 )
        return;
    // search in the background thread
    NSString * column;
    switch( self->_searchScope )
    {
       case 1 :
           column = @"ingredients";
           break;
           
       case 2 :
           column = @"instructions";
           break;
           
       default :
           column = @"name";
           break;
    }
    NSString * strFilter = [NSString stringWithFormat:@"%@ LIKE '%%%@%%'", column, searchText];
    self.searcharray1 = [self.database getUnlockedRecordList:YES filter:strFilter addName:NO];
    self.searcharray2 = [self.database getUnlockedRecordList:NO filter:strFilter addName:NO];
    [self.tableSearch reloadData];
}

#pragma mark -- IN-APP purchase support

- (void) productFetchComplete:(MKStoreManager *)storeManager
{
    self.navigationItem.rightBarButtonItem.enabled = [[MKStoreManager sharedManager] canPruchaseUnlockAll];
}

- (void) productPurchased:(NSString *)productId storeManager:(MKStoreManager *)storeManager
{
#ifdef GOOGLE_ANALYTICS
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id_Purchase_%@", productId],
                                     kFIRParameterContentType:@"Game"
                                     }];
#endif // GOOGLE_ANALYTICS
    if ( [MKStoreManager featureUnlockAllPurchased] && [productId isEqualToString:[MKStoreManager featureUnlockAllID]] )
    {
        self.database.unlocked = YES;
        [self.navigationItem.rightBarButtonItem setTitle:LOC(@"Unlocked")];
        self.alcoholic = [self.database getUnlockedRecordList:YES filter:nil addName:NO];
        self.non_alcoholic = [self.database getUnlockedRecordList:NO filter:nil addName:NO];

        // reload data
//        dispatch_queue_t q_default;
//        q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//        dispatch_async( q_default, ^(void)
//           {
//               @synchronized( self )
//               {
//                   @autoreleasepool
//                   {
//                       // search in the background thread
//                       NSArray * alc = [self.database getUnlockedRecordList:YES filter:nil addName:NO];
//                       NSArray * non_alc = [self.database getUnlockedRecordList:NO filter:nil addName:NO];
//
//                       dispatch_queue_t q_main = dispatch_get_main_queue();
//                       dispatch_sync(q_main, ^(void)
//                         {
//                             self.alcoholic = alc;
//                             self.non_alcoholic = non_alc;
//                             [self.tableView reloadData];
//                         });
//                   }
//               }
//           });
    }
}

- (void) transactionCanceled:(MKStoreManager *)storeManager
{
}

- (void) transactionsRestored:(MKStoreManager *)storeManager
{
    if ( ![MKStoreManager featureUnlockAllPurchased] )
    {
        [storeManager buyFeatureUnlockAll];
    }
    else
    {
        [utils showUserMessage:LOC( @"You have already purchased this item. You will not be charged again." ) withTitle:@"App Store"];
    }
}


@end
