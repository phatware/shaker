//
//  OptionsViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/26/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "OptionsViewController.h"
#import "utils.h"
#import "PhatWareAboutViewController.h"
#import "SoundManager.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS

enum OptionsSections
{
    kOptionsSectionAboutSection = 1,
    kOptionsSectionShowAll,
    kOptionsSectionHideDisclaimer,
    kOptionsSectionPlayMusic,
    kOptionsSectionMusicVolume,
    kOptionsSectionUnlockAll,
    kOptionsSectionRemoveAd,
    kOptionsSectionRestorePurchases,
    kOptionsTotalSections,
};

static NSInteger sections[kOptionsTotalSections] = {0};

@interface OptionsViewController ()
{
    NSInteger product;
}

@end

@implementation OptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString( @"Options", @"" );
    UIBarButtonItem * buttonItemDone = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.navigationItem.leftBarButtonItem = buttonItemDone;
    
    if ( (![MKStoreManager featureDisableAdsPurchased]) || (![MKStoreManager featureUnlockAllPurchased]) )
    {
        [MKStoreManager sharedManager].delegate = self;
        if ( (! [[MKStoreManager sharedManager] canPruchaseDisableAds]) || (! [[MKStoreManager sharedManager] canPruchaseUnlockAll]) )
        {
            [[MKStoreManager sharedManager] requestProductData];
        }
    }
}

- (void) doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UISwitch *) createSwitch:(BOOL)on tag:(NSInteger)tag
{
    UISwitch * sw = [[UISwitch alloc] init];
    [sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    sw.on = on;
    sw.tag = tag;
    return sw;
}

- (UISlider *) createSlider:(float)value tag:(NSInteger)tag
{
    UISlider * slider = [[UISlider alloc] init];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    slider.value = value;
    slider.minimumValue = 0.0;
    slider.maximumValue = 1.0;
    slider.tag = tag;
    return slider;
}

- (void) switchAction:(UISwitch *)sw
{
    if ( sw.tag == kOptionsSectionUnlockAll )
    {
        [[utils shakerGroupUserDefaults] setBool:sw.on forKey:kShakerAllRecipesVisible];
        [[utils shakerGroupUserDefaults] synchronize];
    }
    if ( sw.tag == kOptionsSectionShowAll )
    {
        [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:kShakerShowAllIngredients];
    }
    if ( sw.tag == kOptionsSectionHideDisclaimer )
    {
        [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:kShakerHideDisclaimer];
    }
    if ( sw.tag == kOptionsSectionPlayMusic )
    {
        [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:kShakerPlayMusic];
    }
}

- (void) sliderAction:(UISlider *)slider
{
    float volume = slider.value;
    [[NSUserDefaults standardUserDefaults] setFloat:volume forKey:kShakerMusicVolume];
    [SoundManager sharedManager].musicVolume = volume;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger sect = 0;
    sections[sect++] = kOptionsSectionAboutSection;
    sections[sect++] = kOptionsSectionShowAll;
    sections[sect++] = kOptionsSectionHideDisclaimer;
    sections[sect++] = kOptionsSectionPlayMusic;
    sections[sect++] = kOptionsSectionMusicVolume;
    sections[sect++] = kOptionsSectionUnlockAll;
    if ( ! [MKStoreManager featureDisableAdsPurchased] )
    {
        sections[sect++] = kOptionsSectionRemoveAd;
    }
    if ( (! [MKStoreManager featureUnlockAllPurchased]) || (! [MKStoreManager featureDisableAdsPurchased]) )
    {
        sections[sect++] = kOptionsSectionRestorePurchases;
    }
    return sect;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 5.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 8.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * kCellIdentifier = @"WP_OptionsCellID";
    
    UITableViewCell *	cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    if ( row > 1 )
        return cell;
    
    if ( sections[section] == kOptionsSectionAboutSection )
    {
        cell.textLabel.text = LOC( @"About Shaker" );
    }
    if ( sections[section] == kOptionsSectionShowAll )
    {
        cell.textLabel.text = LOC( @"Show All Ingredients" );
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:kShakerShowAllIngredients] tag:kOptionsSectionShowAll];
        cell.detailTextLabel.text = LOC( @"Shows all ingredients (over 2,000)" );
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if ( sections[section] == kOptionsSectionPlayMusic )
    {
        cell.textLabel.text = LOC( @"Play Music" );
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:kShakerMusicVolume] tag:kOptionsSectionPlayMusic];
        cell.detailTextLabel.text = LOC( @"Plays background music when showing recipe." );
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if ( sections[section] == kOptionsSectionHideDisclaimer )
    {
        cell.textLabel.text = LOC( @"Hide Disclaimer" );
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:kShakerHideDisclaimer] tag:kOptionsSectionHideDisclaimer];
        cell.detailTextLabel.text = LOC( @"Hides disclaimer at startup." );
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if ( sections[section] == kOptionsSectionMusicVolume )
    {
        cell.textLabel.text = LOC( @"Music Volume" );
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = [self createSlider:[[NSUserDefaults standardUserDefaults] floatForKey:kShakerMusicVolume] tag:kOptionsSectionMusicVolume];
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if ( sections[section] == kOptionsSectionUnlockAll )
    {
        if ( [MKStoreManager featureUnlockAllPurchased] )
        {
            cell.textLabel.text = LOC( @"Show All Recipes" );
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryView = [self createSwitch:[[utils shakerGroupUserDefaults] boolForKey:kShakerAllRecipesVisible] tag:kOptionsSectionUnlockAll];
            cell.detailTextLabel.text = LOC( @"Shows all recipes (over 16,000)" );
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            cell.textLabel.text = LOC( @"Unlock All Recipes" );
            cell.detailTextLabel.text = LOC( @"Unlock all 16,000 recipes ($1.99)" );
            if ( ! [[MKStoreManager sharedManager] canPruchaseUnlockAll] )
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
    }
    if ( sections[section] == kOptionsSectionRemoveAd )
    {
        cell.textLabel.text = LOC( @"Remove Advertisement" );
        cell.detailTextLabel.text = LOC( @"Permanently remove ad bar ($1.99)" );
        if ( ! [[MKStoreManager sharedManager] canPruchaseDisableAds] )
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor grayColor];
        }
    }
    if ( sections[section] == kOptionsSectionRestorePurchases )
    {
        cell.textLabel.text = LOC( @"Restore Purchases" );
        cell.detailTextLabel.text = LOC( @"Restores in-app purchases." );
        cell.accessoryType = UITableViewCellAccessoryNone;
        if ( (! [[MKStoreManager sharedManager] canPruchaseUnlockAll]) && (! [[MKStoreManager sharedManager] canPruchaseDisableAds]) )
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor grayColor];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     To conform to the Human Interface Guidelines, selections should not be persistent --
     deselect the row after it has been selected.
     */
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    if ( sections[section] == kOptionsSectionAboutSection )
    {
        if ( row == 0 )
        {
            PhatWareAboutViewController * viewController = [[PhatWareAboutViewController alloc] initWithStyle:(UITableViewStyleGrouped)];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
    if ( sections[section] == kOptionsSectionUnlockAll )
    {
#ifdef GOOGLE_ANALYTICS
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                         kFIRParameterItemID:@"id_UnlockAll",
                                         kFIRParameterContentType:@"UX"
                                         }];
#endif // GOOGLE_ANALYTICS
        product = 2;
        [[MKStoreManager sharedManager] buyFeatureUnlockAll];
        // [[MKStoreManager sharedManager] restorePreviousTransactions];
    }
    if ( sections[section] == kOptionsSectionRemoveAd )
    {
#ifdef GOOGLE_ANALYTICS
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                         kFIRParameterItemID:@"id_RemoveAds",
                                         kFIRParameterContentType:@"UX"
                                         }];
#endif // GOOGLE_ANALYTICS
        product = 1;
        [[MKStoreManager sharedManager] buyFeatureDisableAds];
        // [[MKStoreManager sharedManager] restorePreviousTransactions];
    }
    if ( sections[section] == kOptionsSectionRestorePurchases )
    {
        [[MKStoreManager sharedManager] restorePreviousTransactions];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- IN-APP Purchase

- (void) productFetchComplete:(MKStoreManager *)storeManager
{
    [self.tableView reloadData];
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
    [self.tableView reloadData];
}

- (void) transactionCanceled:(MKStoreManager *)storeManager
{
}

- (void) transactionsRestored:(MKStoreManager *)storeManager
{
    /*
    if ( product == 2 && (![MKStoreManager featureUnlockAllPurchased]) )
    {
        [storeManager buyFeatureUnlockAll];
    }
    else if ( product == 1 && (![MKStoreManager featureDisableAdsPurchased]) )
    {
        [storeManager buyFeatureDisableAds];
    }
    */
    if ( [MKStoreManager featureUnlockAllPurchased] || [MKStoreManager featureDisableAdsPurchased] )
    {
        [utils showUserMessage:LOC( @"Your in-app purchases have been restored." ) withTitle:@"App Store"];
        [self.tableView reloadData];
    }
    else
    {
        [utils showUserMessage:LOC( @"You have not made any in-app purchases yet." ) withTitle:@"App Store"];
    }
}


@end
