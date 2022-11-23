//
//  FavoritesViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/3/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "FavoritesViewController.h"
#import "RecipeViewController.h"
#import "utils.h"

static NSString * kCellIdentifier = @"CELL_ID_1909287402365";

@interface FavoritesViewController ()

@property (nonatomic, strong) NSArray *  favorites;
@property (nonatomic, strong) NSString * deftext;

@end

@implementation FavoritesViewController


- (void) reloadData
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
                   NSArray * fav = [self.database getFavorites:(self.recipesPresnetation==kRecipeViewPresentationLike)
                                                           all:NO
                                                     isAlcogol:YES];
                   
                   dispatch_queue_t q_main = dispatch_get_main_queue();
                   dispatch_sync(q_main, ^(void)
                     {
                         if ( [fav count] < 1 )
                         {
                             self.deftext = (self.recipesPresnetation==kRecipeViewPresentationLike) ?
                                            LOC( @"Drinks rated 5+ stars appear here" ) :
                                            LOC( @"Drinks rated below 5 stars appear here" );
                         }
                         self.favorites = fav;
                         [self.tableView reloadData];
                     });
               }
           }
       });
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.deftext = LOC( @"Loading..." );
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    self.favorites = nil;
    
    [self reloadData];
    
    self.title = (self.recipesPresnetation==kRecipeViewPresentationLike) ? LOC( @"Favorites" ) : LOC( @"Disliked" );
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger result = [self.favorites count];
    return result == 0 ? 1 : result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    // NSInteger section = [indexPath section];
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";

    if ( row < [self.favorites count] )
    {
        NSDictionary * info = [self.favorites objectAtIndex:row];
        cell.tag = (NSInteger)[[info objectForKey:@"id"] longLongValue];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = [info objectForKey:@"name"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        NSString * str = @"";
        for ( int i = 0; i < [[info objectForKey:@"rating"] intValue]; i++ )
        {
            str = [str stringByAppendingString:@"⭐️"];
        }
        cell.detailTextLabel.text = str;
        
        str = [NSString stringWithFormat:@"rate%d", [[info objectForKey:@"rating"] intValue]];
        cell.imageView.image = [UIImage imageNamed:str]; // [utils colorImageWithName:str color:cell.tintColor mode:kCGBlendModeCopy];
    }
    else if ( row == 0 )
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = self.deftext;
        cell.textLabel.textColor = self.tableView.tintColor;
        cell.imageView.image = nil;
    }
    return cell;
}

- (void) ratingChanged:(int)newrating
{
    [self reloadData];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    if ( row < [self.favorites count] )
    {
        sqlite3_int64  record = [[[self.favorites objectAtIndex:row] objectForKey:@"id"] longLongValue];
        NSDictionary * recipe = [self.database getRecipe:record alcohol:YES noImage:NO];
        if ( recipe != nil )
        {
            // show recipe
            RecipeViewController * rc = [[RecipeViewController alloc] init];
            rc.delegate = (id)self;
            rc.recipe = recipe;
            rc.database = self.database;
            [self.navigationController pushViewController:rc animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
