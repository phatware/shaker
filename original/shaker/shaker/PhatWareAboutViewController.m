//
//  PhatWareAboutViewController.m
//  Shaker
//
//  Created by Stanislav Miasnikov on 11/1/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "PhatWareAboutViewController.h"
#import "SourceCell.h"
#import "CellLabelView.h"
#import "utils.h"
#import "Reachability.h"
#import "UIConst.h"
#import "RateApplication.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS

static NSString *kCellIdentifier = @"MyIdentifier";

@interface PhatWareAboutViewController ()

@end

@implementation PhatWareAboutViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = LOC( @"About Shaker" );
    
#ifdef UPDATE_TO_WRITEPAD_PRO
    if ( [self goPro] )
    {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSTimeInterval installed = [defaults doubleForKey:kWritePadInstalledDate];
        NSInteger update_key = [defaults integerForKey:kWriteProUpdateKey];
        NSInteger count = [defaults integerForKey:kWritePadStartCount];
        
        if ( count >= AD_SHOW_COUNT && ([[NSDate date] timeIntervalSinceReferenceDate] - installed) >= AD_TIME_INTERVAL && update_key < 1 )
        {
            [self performSelector:@selector(informAbout) withObject:nil afterDelay:2.0];
        }
    }
#endif

    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Update to WritePad Pro

#ifdef UPDATE_TO_WRITEPAD_PRO

- (void) informAbout
{
    NSString * strAlert = NSLocalizedString( @"Penquills combines advanced note-taking and word processing functionality with with sketch/drawing capabilities, numerous file sharing options, and superb handwriting recognition to create the ultimate writing app.", @"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"Get Penquills App", @"")
                                                    message:strAlert
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:
                          NSLocalizedString( @"Show More Info...", @"" ),
                          NSLocalizedString( @"Remind Me Later", @"" ),
                          NSLocalizedString( @"Don't Remind Again", @"" ),
                          nil];
    alert.tag = 25;
    [alert show]; // show from our table view (pops up in the middle of the table)
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( alertView.tag != 25 )
        return;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    switch ( buttonIndex)
    {
        case 0 :
            // show app store listing.
            [self openAppStore:self delegate:self];
            // if not purchased, will remind again
        case 1 :
            [defaults setInteger:(2) forKey:kWriteProUpdateKey];
            [defaults setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:kShakerPadInstalledDate];
            break;
            
        case 2 :
            [defaults setInteger:AD_DISABLED_CODE forKey:kWriteProUpdateKey];
            break;
    }
    
#ifdef GOOGLE_ANALYTICS
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if ( tracker )
    {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                              action:@"Update"
                                                               label:@"Penquills"
                                                               value:[NSNumber numberWithInteger:(buttonIndex==0) ? 1 : 0]] build]];
    }
#endif // GOOGLE_ANALYTICS
}

- (void)openAppStore:(UIViewController *)viewController delegate:(id)del
{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        // Initialize Product View Controller
        [[UINavigationBar appearance] setTintColor:[utils getCurrentTintColor]];
    }
    
    //#if (! TARGET_IPHONE_SIMULATOR)
    
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    
    __block UIAlertView * progress = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedString( @"Accessing iTunes", @"" )
                                      message:NSLocalizedString( @"Please Wait...", @"" )
                                      delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:nil];
    [progress show];
    
    // Configure View Controller
    [storeProductViewController setDelegate:del];                                                      // 293033512 use this number to test
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @"797238295"} completionBlock:^(BOOL result, NSError *error)
     {
         [progress dismissWithClickedButtonIndex:0 animated:NO];
         
         if (error)
         {
             NSLog(@"Error %@ with User Info %@.", error, [error userInfo]);
             if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
             {
                 [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
             }
             
             NSString * strAlert = [NSString stringWithFormat:NSLocalizedString( @"Unable to access iTunes App Store at this time. Error: %@.", @""), [error localizedDescription]];
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"iTunes Error", @"")
                                                             message:strAlert
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString( @"Cancel", @"" )
                                                   otherButtonTitles:nil];
             [alert show]; // show from our table view (pops up in the middle of the table)
         }
         else
         {
             // Present Store Product View Controller
             [viewController presentViewController:storeProductViewController animated:YES completion:^{
                 storeProductViewController.title = @"WritePad Pro";
             }];
         }
     }];
    
    // #endif // ! TARGET_IPHONE_SIMULATOR
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)vc
{
    [vc dismissViewControllerAnimated:YES completion:nil];
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    }
}

- (BOOL) goPro
{
    if ( [Reachability IsInternetAvaialble] == NotReachable )
        return NO;
    NSTimeInterval installed = [[NSUserDefaults standardUserDefaults] doubleForKey:kWritePadInstalledDate];
    if ( ([[NSDate date] timeIntervalSinceReferenceDate] - installed) < (3600.0) )
        return NO;
    if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"penquills.penquills://"]] )
        return NO;
    return YES;
}

#endif // UPDATE_TO_WRITEPAD_PRO

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[RateApplication sharedInstance] canRate:NO] ? 3 : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
    if ( section == 0 )
        title =  NSLocalizedTableTitle( @"About Shaker" );
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == 0 )
        return 3;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = kUIRowHeight;
	NSUInteger row = [indexPath row];
	NSUInteger section = [indexPath section];
    if ( section == 0 )
    {
        result = KUIAboutBoxHeight+50;
        if ( row == 1 )
            result = kUIRowLabelHeight;
        else if ( row == 2 )
            result = kUIRowLabelHeight;
    }
    return result;
}

- (UITableViewCell *)obtainTableCellForTable:(UITableView*)tableView withRow:(NSInteger)row section:(NSInteger)section
{
	UITableViewCell *cell = nil;
    
	if (row == 0)
		cell = [tableView dequeueReusableCellWithIdentifier:kCellLabelView_ID];
	else if (row == 1 )
		cell = [tableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
	else if ( row == 2 || row == 3 )
		cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	if (cell == nil)
	{
		if (row == 0)
			cell = [[CellLabelView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellLabelView_ID];
		else if (row == 1 )
			cell = [[SourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSourceCell_ID];
		else if (row == 2 || row == 3 )
			cell = [[SourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
	}
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	UITableViewCell *cell = nil;
	
    if ( indexPath.section == 0 )
    {
        if (row == 0)
        {
            cell = [self obtainTableCellForTable:tableView withRow:row section:indexPath.section];
            ((CellLabelView *)cell).nameLabel.text = [utils appNameAndVersionNumberDisplayString];
            ((CellLabelView *)cell).textLabel.text = @"Copyright © 2019 Penquills.\nAll rights reserved.\n\nDedicated to the memory of James Perley.";
            [((CellLabelView *)cell) set_Image:@"phatware_iPhone.png"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if ( row == 2 )
        {
            cell = [self obtainTableCellForTable:tableView withRow:row section:indexPath.section];
            // this cell hosts the info on where to find the code
            ((SourceCell *)cell).sourceLabel.text = @"Designed and Programmed in the USA.";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if ( row == 1 )
        {
            cell = [self obtainTableCellForTable:tableView withRow:row section:indexPath.section];
            // this cell hosts the info on where to find the code
            ((SourceCell *)cell).sourceLabel.text = @"http://www.penquills.com";
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if ( indexPath.section == 1 )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CellID2345646"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID2345646"];
        }
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.8;
        cell.textLabel.text = LOC( @"Send Feedback" );
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:22.0];
        cell.textLabel.textColor = cell.tintColor;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ( indexPath.section == 2 )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CellID24537589"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID24537589"];
        }
        cell.textLabel.text = LOC( @"Rate Shaker" );
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:22.0];
        cell.textLabel.textColor = cell.tintColor;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
#ifdef UPDATE_TO_WRITEPAD_PRO
    else if ( indexPath.section == 2 )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CellID23231423"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID23231423"];
        }
        cell.textLabel.text = @"Get WritePad Pro";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:22.0];
        cell.textLabel.textColor = cell.tintColor;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
#endif // UPDATE_TO_WRITEPAD_PRO
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
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    if ( section == 0 && row == 1 )
    {
        // open the URL... http://www.phatware.com/phatpro
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.penquills.com"] options:@{} completionHandler:^(BOOL success) {
            if ( ! success )
            {
                // show error?
            }
        }];
    }
    else if ( section == 1 && row == 0 )
    {
        if ( [MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController * controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            
            [controller setToRecipients:[NSArray arrayWithObject:@"support@phatware.com"]];
            [controller setSubject:@"Shaker Feedback"];
            
            // generate support email
            
            NSMutableString * strText = [[NSMutableString alloc] initWithFormat:@"\n\n\n\nApp Version: %@\n", [utils appNameAndVersionNumberDisplayString]];
            [strText appendString:[utils getDeviceInfo]];
            [controller setMessageBody:strText isHTML:NO];
            
            // controller.navigationBar.tintColor = [utils getCurrentTintColor];
            [self presentViewController:controller animated:YES completion:nil];
        }
        else
        {
            [UIAlertController showMessage:LOC( @"The device is not configured to send emails." ) withTitle:LOC(@"Email Error")];
            // show warning
        }
#ifdef GOOGLE_ANALYTICS
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                         kFIRParameterItemID:@"id_Facebook",
                                         kFIRParameterContentType:@"UX"
                                         }];
#endif // GOOGLE_ANALYTICS
    }
    else if ( indexPath.section == 2 && row == 0 )
    {
        // rate
        [[RateApplication sharedInstance] promptToRate:[NSNumber numberWithBool:YES]];
        [tableView reloadData];
    }
#ifdef UPDATE_TO_WRITEPAD_PRO
    else if ( indexPath.section == 2 && row == 0 )
    {
        [self openAppStore:self delegate:self];
#ifdef GOOGLE_ANALYTICS
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                         kFIRParameterItemID:@"id_Update_Penquills",
                                         kFIRParameterContentType:@"UX"
                                         }];
#endif // GOOGLE_ANALYTICS
    }
#endif // UPDATE_TO_WRITEPAD_PRO
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	if ( result == MFMailComposeResultFailed )
	{
		NSLog( @"Email has not been sent: %@", error );
		// show error message
		NSString * strAlert = [NSString stringWithFormat:NSLocalizedString( @"Unable to send Email: %@", @""),
							   error ? [error localizedDescription] : NSLocalizedString( @"Unknown Error.", @"" )];

		// show warning
        [UIAlertController showMessage:strAlert withTitle:LOC(@"Email Error")];
	}
    [controller dismissViewControllerAnimated:YES completion:nil];
    // [self performSelector:@selector(onCancel:) withObject:nil afterDelay:0.4];
	// [self.navigationController dismissModalViewControllerAnimated:NO];
}

#pragma mark -- fix separator between rows

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

-(void)viewDidLayoutSubviews
{
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}

@end
