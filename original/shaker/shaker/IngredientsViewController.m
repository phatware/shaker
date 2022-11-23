//
//  IngredientsViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/25/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "IngredientsViewController.h"
#import "utils.h"

static NSString * kCellIdentifier = @"CELL_ID_19074098276592";

@interface IngredientsViewController ()

@property (nonatomic, strong) NSArray * ingredients;
@property (nonatomic, strong) UITableView  * tableSearch;
@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) NSArray * searcharray;
@property (nonatomic, strong) UIBarButtonItem * sortButton;

@end

@implementation IngredientsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL showall = [[NSUserDefaults standardUserDefaults] boolForKey:kShakerShowAllIngredients];
    NSInteger sort = [[NSUserDefaults standardUserDefaults] integerForKey:kShakerIngredientsSortOrder];

    self.ingredients = [self.database inredientsForCategory:self.category_id showall:showall filter:nil sort:((sort==0) ? @"item ASC" : @"used DESC")];

    // UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel:)];
    // self.navigationItem.leftBarButtonItem = doneButton;
    
    UIImage * imgSort = [UIImage imageNamed:((sort==0) ? @"sort_abc" : @"sort_123")];
    NSArray* toolbarItems = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc] initWithTitle:LOC( @"Enable All" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(enableAll:)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                             (self.sortButton = [[UIBarButtonItem alloc] initWithImage:imgSort style:(UIBarButtonItemStylePlain) target:self action:@selector(sort:)]),
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithTitle:LOC( @"Disable All" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(disableAll:)],
                             nil];
    self.toolbarItems = toolbarItems;
    self.navigationController.toolbarHidden = NO;
    
    self.title = LOC( @"Ingredients" );

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
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void) reloadItems
{
    BOOL showall = [[NSUserDefaults standardUserDefaults] boolForKey:kShakerShowAllIngredients];
    NSInteger sort = [[NSUserDefaults standardUserDefaults] integerForKey:kShakerIngredientsSortOrder];
    self.ingredients = [self.database inredientsForCategory:self.category_id showall:showall filter:nil sort:((sort==0) ? @"item ASC" : @"used DESC")];
    [self.tableView reloadData];
}

- (void) enableAll:(id)sender
{
    for ( NSDictionary * ing in self.ingredients )
    {
        [self.database enableIngredient:YES withRecordid:[ing[@"id"] longLongValue]];
    }
    [self reloadItems];
}

- (void) disableAll:(id)sender
{
    for ( NSDictionary * ing in self.ingredients )
    {
        [self.database enableIngredient:NO withRecordid:[ing[@"id"] longLongValue]];
    }
    [self reloadItems];
}

- (void) sort:(id)sender
{
    NSInteger sort = [[NSUserDefaults standardUserDefaults] integerForKey:kShakerIngredientsSortOrder];
    sort = (sort==0) ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:sort forKey:kShakerIngredientsSortOrder];
    [self.sortButton setImage:[UIImage imageNamed:((sort==0) ? @"sort_abc" : @"sort_123")]];
    
    [self reloadItems];
}

- (void) cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
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

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // self.navigationController.toolbarHidden = YES;
}

#pragma mark - Table view data source

- (UISwitch *) createSwitch:(NSDictionary *)ingredient
{
    UISwitch * sw = [[UISwitch alloc] init];
    [sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    sw.on = [ingredient[@"enabled"] boolValue];
    sw.tag = (NSInteger)[ingredient[@"id"] longLongValue];
    return sw;
}

- (void) switchAction:(UISwitch *)sw
{
    @autoreleasepool
    {
        BOOL search = [self.searchController isActive] && self.searcharray != nil;
        NSMutableArray * arrIng = (search) ? [self.searcharray mutableCopy] : [self.ingredients mutableCopy];
        if ( sw.tag < [arrIng count] )
        {
            NSMutableDictionary * ing = [arrIng[sw.tag] mutableCopy];
            if ( ing )
            {
                [self.database enableIngredient:sw.on withRecordid:[ing[@"id"] longLongValue]];
                [ing setObject:@(sw.on) forKey:@"enabled"];
                [arrIng replaceObjectAtIndex:sw.tag withObject:ing];
                if ( search )
                    self.searcharray = (NSArray *)arrIng;
                else
                    self.ingredients = (NSArray *)arrIng;
            }
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( [tableView isEqual:self.tableSearch] )
        return [self.searcharray count];
    return [self.ingredients count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary * ingredient;
    if ( [tableView isEqual:self.tableSearch] )
    {
        if ( row < [self.searcharray count] )
            ingredient = [self.searcharray objectAtIndex:row];
    }
    else
    {
        if ( row < [self.ingredients count] )
            ingredient = [self.ingredients objectAtIndex:row];
    }
    if ( nil == ingredient )
    {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        cell.accessoryView = nil;
    }
    else
    {
        UISwitch * sw = [self createSwitch:ingredient];
        sw.tag = row;
        cell.textLabel.text = ingredient[@"name"];
        cell.accessoryView = sw;
        cell.textLabel.textColor = [ingredient[@"visible"] boolValue] ? [UIColor blackColor] : [UIColor darkGrayColor];
        cell.detailTextLabel.text = [NSString stringWithFormat:LOC(@"It is used in %d recipes"), [ingredient[@"used"] intValue]];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    
    if ( row < [self.ingredients count] )
    {
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark -- Search

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [searchController.searchBar text];
    [self filterContentForSearchText:searchString];
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    // NSLog( @"didPresentSearchController" );
    // self.tableSearch.frame = self.view.bounds;
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.searcharray = nil;
}

- (void) filterContentForSearchText:(NSString*)searchText
{
    if ( [searchText length] < 1 )
        return;
   // search in the background thread
   BOOL showall = [[NSUserDefaults standardUserDefaults] boolForKey:kShakerShowAllIngredients];
   NSInteger sort = [[NSUserDefaults standardUserDefaults] integerForKey:kShakerIngredientsSortOrder];
   NSArray * filtered = [self.database inredientsForCategory:self.category_id
                                                     showall:showall
                                                      filter:[NSString stringWithFormat:@"item LIKE '%%%@%%'", searchText]
                                                        sort:((sort==0) ? @"item ASC" : @"used DESC")];
    self.searcharray = filtered;
    [self.tableSearch reloadData];
}

/*
- (void) recalcSections
{
    [self.sections removeAllObjects];
    
    unichar chr, ch0 = [self.ingredients[0][@"name"] characterAtIndex:0];;
    NSInteger index0 = 0;
    NSInteger cnt = [self.ingredients count];
    // create sections for indexing
    for (NSInteger i = 1; i < cnt; i++)
    {
        chr = [self.ingredients[i][@"name"] characterAtIndex:0];
        chr = toupper(chr);
        if (chr != ch0)
        {
            [_sections addObject:@{ @"name"   : [NSString stringWithCharacters:&ch0 length:1],
                                    @"index"  : @(index0),
                                    @"length" : @(i-index0)}];
            index0 = i;
            ch0 = chr;
        }
    }
    if (index0 < cnt)
    {
        [_sections addObject:@{ @"name"   : [NSString stringWithCharacters:&ch0 length:1],
                                @"index"  : @(index0),
                                @"length" : @(cnt-index0) }];
    }
}
*/

@end
