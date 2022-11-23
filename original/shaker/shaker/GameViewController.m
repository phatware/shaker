//
//  GameViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/14/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <Social/Social.h>
#import "GameViewController.h"
#import "ShakeView.h"

#import "CoctailsDatabase.h"
#import "UIPhotoView.h"
#import "Reachability.h"
#import "utils.h"
#import "RecipesViewController.h"
#import "OptionsViewController.h"
#import "MKStoreManager.h"
#import "FavoritesViewController.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS
#ifdef GOOGLE_ADMOB
#import <GoogleMobileAds/GoogleMobileAds.h>
#endif // GOOGLE_ADMOB
#ifdef TWITTER_SUPPORT
#import <TwitterKit/TWTRKit.h>
#endif // TWITTER_SUPPORT
#define kRatingsHeight 56

@interface GameViewController()
#ifdef GOOGLE_ADMOB
<GADInterstitialDelegate>
#endif
{
    NSInteger play_count;
}

#ifdef GOOGLE_ADMOB
@property(nonatomic, strong) GADInterstitial * interstitial;
#endif // GOOGLE_ADMOB

@property (nonatomic, strong) MenuScene * menu;
@property (nonatomic, strong) GameScene * game;
// TODO: use adMob

@end

#ifdef GOOGLE_ADMOB
#define ADMOB_MAINMENU_ID   @"ca-app-pub-7887103971395610/8165854381"
#endif // GOOGLE_ADMOB

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file
{
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSError * err = nil;
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&err];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
    return scene;
}

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    
    // skView.showsFPS = YES;
    // skView.showsNodeCount = YES;
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    // skView.ignoresSiblingOrder = YES;

    CoctailsDatabase * database = [[CoctailsDatabase alloc] init];
    [database initializeDatabase];
    
    play_count = 0;
    
    // Create and configure the scene.
    self.game = [[GameScene alloc] initWithSize:self.view.bounds.size inView:skView];
    self.game.scaleMode = SKSceneScaleModeAspectFill;
    self.game.coctails = database;
    self.game.mydelegate = self;
    
    self.menu = [[MenuScene alloc] initWithSize:self.view.bounds.size inView:skView];
    self.menu.scaleMode = SKSceneScaleModeAspectFill;
    self.menu.mydelegate = self;

    // TODO: uncomment for screenshots/testing
    // [MKStoreManager updateUnlockAllPurchase];
    // [MKStoreManager updateDisableAdsPurchase];

    // Present the scene.
    [skView presentScene:self.menu];
    
    ShakeView * s = [[ShakeView alloc] init];
    s.opaque = NO;
    s.delegate = self.game;
    s.ignoreEvents = YES;
    self.game.shakeview = s;
    s.backgroundColor = [UIColor clearColor];
    [[self view] addSubview:s];
    [s becomeFirstResponder];
    
#ifdef GOOGLE_ADMOB
    self.interstitial = [self createAndLoadInterstitial];
#endif // GOOGLE_ADMOB

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(takePhoto:) name:TAKE_PHOTO_NOTIFICATION object:nil];
}

- (void)layoutAnimated:(BOOL)animated
{
    // As of iOS 6.0, the banner will automatically resize itself based on its width. <== apperently this does not work in iOS 7, had to use it anyway
    // To support iOS 5.0 however, we continue to set the currentContentSizeIdentifier appropriately.
}

- (void)viewDidLayoutSubviews
{
    [self layoutAnimated:[UIView areAnimationsEnabled]];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else
    {
        return UIInterfaceOrientationMaskAll;
    }
}

- (GameScene *) getGameScene
{
    SKView *    skView = (SKView *)self.view;
    SKScene *   scene = skView.scene;
    if ( [scene isKindOfClass:[GameScene class]] )
    {
        return (GameScene *)scene;
    }
    return nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    GameScene * scene = [self getGameScene];
    if ( scene )
        [scene.shakeview becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    //[self.view becomeFirstResponder];
    [super viewWillAppear:animated];
}
- (void) viewWillDisappear:(BOOL)animated
{
    //[self.view resignFirstResponder];
    [super viewWillDisappear:animated];
}

#define Y_OFFSET    5.0
#define X_OFFSET    20.0
#define H_CMDFRAME  64.0
#define DEF_WIDTH   ((self.view.frame.size.width > 350.0) ? 50.0 : 36.0)
#define MAX_WIDTH   ((self.view.frame.size.width > 350.0) ? 330.0 : 290.0)

- (BOOL) buttonPressed:(UIButton *)button recipe :(NSDictionary *)recpie
{
    NSString * strSyncService = @"";
    switch ( button.tag )
    {
        case kGameCommandShare : // share
        {
            strSyncService = @"Share";
            if ( [Reachability IsInternetAvaialble] == NotReachable )
            {
                // show warning
                [utils networkConnectionWarning];
                break;
            }
            CGRect frame = CGRectMake( X_OFFSET, 0.0, self.view.bounds.size.width - 2 * X_OFFSET, H_CMDFRAME );
            UIShareView * shareView = [[UIShareView alloc] initWithFrame:frame];
            shareView.bottomArrow = YES;
            shareView.delegate = self;
            CGPoint pos = CGPointMake( CGRectGetMidX( button.frame ), CGRectGetMinY(button.frame) - Y_OFFSET );
            [shareView presentInView:self.view fromPoint:pos animated:YES];
        }
            break;
            
        case kGameCommandNote :  // note
        {
            strSyncService = @"Note";
            CGFloat y = (self.view.frame.size.width > 350.0) ? 100.0 : 50.0;
            CGFloat h = (self.view.frame.size.width > 350.0) ? 250.0 : 210.0;
            CGRect frame = CGRectMake( DEF_WIDTH/2.0, y, (self.view.bounds.size.width - DEF_WIDTH), h );
            UINoteView * noteView = [[UINoteView alloc] initWithFrame:frame initialText:[recpie objectForKey:@"note"]];
            noteView.bottomArrow = NO;
            noteView.yOffset = y;
            noteView.delegate = self;
            CGPoint pos = CGPointZero;
            [noteView presentInView:self.view fromPoint:pos animated:YES];
        }
            break;
            
        case kGameCommandPhoto :  // picture
        {
            strSyncService = @"Picture";
            UIImage * image = [recpie objectForKey:@"photo"];
            if ( image == nil )
            {
                [self insertImageDialog:UIImagePickerControllerSourceTypeCamera];
            }
            else
            {
                CGRect frame = CGRectMake( 0.0, 0.0, (self.view.bounds.size.width - DEF_WIDTH), MAX_WIDTH );
                UIPhotoView * photoview = [[UIPhotoView alloc] initWithFrame:frame image:image];
                photoview.bottomArrow = YES;
                CGPoint pos = CGPointMake( CGRectGetMidX( button.frame ), CGRectGetMinY(button.frame) - Y_OFFSET );
                [photoview presentInView:self.view fromPoint:pos animated:YES];
            }
        }
            break;
            
        case kGameCommandShopping :  // shopping
        {
            strSyncService = @"Shopping";
            if ( [Reachability IsInternetAvaialble] == NotReachable )
            {
                // show warning
                [utils networkConnectionWarning];
                break;
            }
            CGRect frame = CGRectMake( self.view.bounds.size.width/2.0, 0.0, self.view.bounds.size.width/2.0 - X_OFFSET, H_CMDFRAME );
            UIShoppingView * shoppingView = [[UIShoppingView alloc] initWithFrame:frame];
            shoppingView.bottomArrow = YES;
            shoppingView.delegate = self;
            CGPoint pos = CGPointMake( CGRectGetMidX( button.frame ), CGRectGetMinY(button.frame) - Y_OFFSET );
            [shoppingView presentInView:self.view fromPoint:pos animated:YES];
        }
            break;
            
        case kGameCommandRate :  // rate
        {
            strSyncService = @"Rate";
            CGRect frame = CGRectMake( 0.0, 0.0, (self.view.bounds.size.width - DEF_WIDTH), kRatingsHeight );
            UIRatingView * ratingview = [[UIRatingView alloc] initWithFrame:frame];
            ratingview.rating = [[recpie objectForKey:@"userrating"] intValue];
            ratingview.userRating = YES;
            ratingview.bottomArrow = YES;
            ratingview.delegate = self;
            if ( ratingview.rating < 1 )
            {
                ratingview.rating = [[recpie objectForKey:@"rating"] intValue];
                ratingview.userRating = NO;
            }
            CGPoint pos = CGPointMake( CGRectGetMidX( button.frame ), CGRectGetMinY(button.frame) - Y_OFFSET );
            [ratingview presentInView:self.view fromPoint:pos animated:YES];
        }
            break;
            
        default:
            return NO;
            break;
    }
#ifdef GOOGLE_ANALYTICS
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id_Button_%@", strSyncService],
                                     kFIRParameterContentType:@"Game"
                                     }];
#endif // GOOGLE_ANALYTICS
    return YES;
}

- (void) onSetNoteText:(NSString *)text
{
    if ( [text length] > 0 )
    {
        GameScene * scene = [self getGameScene];
        if ( scene == nil )
            return;
        NSMutableDictionary * recipe  = [scene.current_recipe  mutableCopy];
        [recipe  setObject:text forKey:@"note"];
        scene.current_recipe  = [recipe  copy];
        sqlite3_int64 recid = [[recipe  objectForKey:@"userrecord_id"] longLongValue];
        [scene.coctails updateUserRecord:recid note:text rating:[[recipe  objectForKey:@"userrating"] intValue] visible:YES];
    }
}

- (void) takePhoto:(NSNotification *)notification
{
    [self insertImageDialog:UIImagePickerControllerSourceTypeCamera];    
}

- (void) insertImageDialog:(UIImagePickerControllerSourceType)sourceType
{
    
    if ( ![UIImagePickerController isSourceTypeAvailable:sourceType] )
    {
        [utils showUserMessage:LOC(@"Camera is unavailable.") withTitle:LOC(@"Camera Error")];
        return;
    }
    
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    picker.allowsEditing = (UIImagePickerControllerSourceTypeCamera == sourceType) ? YES : NO;
    // picker.allowsImageEditing = YES;

    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editingInfo
{
    // NSLog( @"%@", editingInfo );
    UIImage * image = [editingInfo objectForKey:UIImagePickerControllerEditedImage];
    GameScene * scene = [self getGameScene];
    NSDictionary * recipe  = scene.current_recipe ;
    if ( nil != recipe  )
    {
        sqlite3_int64 recid = [[recipe  objectForKey:@"userrecord_id"] longLongValue];
        if ( [scene.coctails updateUserPhoto:image record:recid] )
        {
            NSMutableDictionary * recipe  = [scene.current_recipe  mutableCopy];
            [recipe  setObject:image forKey:@"photo"];
            scene.current_recipe  = [recipe  copy];
        }
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [[self getGameScene] becomeFirstResponder];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [[self getGameScene] becomeFirstResponder];
    }];
}

- (BOOL) ratingView:(UIRatingView *)view rating:(int)rating
{
    GameScene * scene = [self getGameScene];
    if ( scene == nil )
        return NO;
    NSMutableDictionary * recipe  = [scene.current_recipe  mutableCopy];
    [recipe  setObject:[NSNumber numberWithInt:rating] forKey:@"userrating"];
    scene.current_recipe  = [recipe  copy];
    sqlite3_int64 recid = [[recipe  objectForKey:@"userrecord_id"] longLongValue];
    BOOL result = [scene.coctails updateUserRecord:recid note:[recipe  objectForKey:@"note"] rating:rating visible:YES];
    return result;
}

#pragma mark -- Share functions

- (void) onSendMessage:(UIButton *)sender using:(NSInteger)service
{
    GameScene * scene = [self getGameScene];
    if ( scene == nil )
        return;
    
    switch (service)
    {
#ifdef FB_SUPPORT
        case kShareServiceFacebook :
            [self onFacebook:scene.current_recipe ];
            break;
#endif // FB_SUPPORT
#ifdef TWITTER_SUPPORT
        case kShareServiceTwitter :
            [self onTwitter:scene.current_recipe ];
            break;
#endif // TWITTER_SUPPORT
            
        case kShareServiceMessage :
            [self onSendSMS:scene.current_recipe ];
            break;
        
        case kShareServiceMail :
            [self onSendEmail:scene.current_recipe ];
            break;
    }
}

- (void) onSendShoppingList:(UIButton *)sender using:(NSInteger)service
{
    GameScene * scene = [self getGameScene];
    if ( scene == nil )
        return;
    
    switch (service)
    {
        case kShareServiceMessage :
            [self onSendShoppingSMS:scene.current_recipe ];
            break;
            
        case kShareServiceMail :
            [self onSendShoppingEmail:scene.current_recipe ];
            break;

        case kShareServiceCopy :
            [self onCopy:scene.current_recipe ];
            break;
    }
}

- (void) onCopy:(NSDictionary *)recipe
{
    UIPasteboard * appPasteBoard = [UIPasteboard generalPasteboard];
    NSString * text = [NSString stringWithFormat:LOC( @"Ingredients for \"%@\": %@" ), [recipe  objectForKey:@"name"], [recipe  objectForKey:@"shopping"]];
    [appPasteBoard setString:text];
}

- (void) onFacebook:(NSDictionary *)recipe
{
    // TODO: add Facebook SDK
}

#ifdef TWITTER_SUPPORT

- (void) onTwitter:(NSDictionary *)recipe
{
    if ( [Reachability IsInternetAvaialble] == NotReachable )
    {
        // show warning
        [UIAlertController networkConnectionWarningWithSettings];
        return;
    }

    // default text can be improved
    NSString * text = LOC( @"Drinking " );
    text = [text stringByAppendingFormat:@"\"%@\"", [recipe  objectForKey:@"name"]];
    int rating = [[recipe  objectForKey:@"userrating"] intValue];
    if ( rating > 0 && rating <= 10 )
    {
        text = [text stringByAppendingFormat:@" (my rating: %d/10)", rating];
    }
    text = [text stringByAppendingString:@" #shaker"];
    UIImage * image = [recipe  objectForKey:@"photo"];

    if ([[Twitter sharedInstance].sessionStore hasLoggedInUsers])
    {
        TWTRComposerViewController * composer = [[TWTRComposerViewController alloc] initWithInitialText:text image:image videoURL:nil];
        [self presentViewController:composer animated:YES completion:^{
            // composer.navigationController.navigationBar.barTintColor = [UIColor barTintColor];
            // composer.navigationController.navigationBar.tintColor = [UIColor navTintColor];
        }];
    }
    else
    {
        [[Twitter sharedInstance] logInWithViewController:self completion:^(TWTRSession *session, NSError *error)
         {
             if (session)
             {
                 TWTRComposerViewController * composer = [[TWTRComposerViewController alloc] initWithInitialText:text image:image videoURL:nil];
                 [self presentViewController:composer animated:YES completion:^{
                     // composer.navigationController.navigationBar.barTintColor = [UIColor barTintColor];
                     // composer.navigationController.navigationBar.tintColor = [UIColor navTintColor];
                 }];
             }
             else
             {
                 [UIAlertController showMessage:LOC( @"You must log in before presenting a composer." )
                                      withTitle:LOC( @"No Twitter Accounts Available" )];
             }
         }];
    }
}
#endif // TWITTER_SUPPORT

-(void) onSendShoppingEmail:(NSDictionary *)recipe
{
    if ( [MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController * controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        
        NSString * url = @"http://www.phatware.com/shaker"; // TODO: change to the store URL
        
        // TODO: make localizable in the future...
        NSString * html = [NSString stringWithFormat:@"<html> <head>"
                           "<style type=\"text/css\">\nbody {font-family: \"Verdana\"; font-size: 17px;}\n-webkit-touch-callout: none;\n</style>"
                           "<style type=\"text/css\">\na {color:blue; text-decoration:none; font-size: 20px;}</style>"
                           "</head><body><p><b>Ingredients for %@:</b></p><p> %@</p>"
                           "<p><br></p> <p>Composed with <a href=\"%@\">Shaker</a> </p></body></html>",
                           [recipe  objectForKey:@"name"],
                           [recipe  objectForKey:@"shopping"], url];
        
        [controller setMessageBody:html isHTML:YES];
        [controller setSubject:[NSString stringWithFormat:@"Ingredients for \"%@\"", [recipe  objectForKey:@"name"]]];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        // show warning
        [utils showUserMessage:LOC( @"The device is not configured to send emails." ) withTitle:LOC( @"Email Error" )];
    }

}

-(void) onSendShoppingSMS:(NSDictionary *)recipe
{
    if ( [MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController * picker = [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        
        NSString * text = [NSString stringWithFormat:LOC( @"Ingredients for \"%@\": %@" ), [recipe  objectForKey:@"name"], [recipe  objectForKey:@"shopping"]];
        picker.body = text;
        [self presentViewController:picker animated:YES completion:nil];
    }
    else
    {
        [utils showUserMessage:LOC( @"The device is not configured to send messages." ) withTitle:LOC( @"Message Error" )];
    }
}


-(void) onSendSMS:(NSDictionary *)recipe 
{
    if ( [MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController * picker = [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        
        // TODO: default text can be improved
        NSString * text = LOC( @"Drinking " );
        text = [text stringByAppendingFormat:@"\"%@\"", [recipe  objectForKey:@"name"]];
        int rating = [[recipe  objectForKey:@"userrating"] intValue];
        if ( rating > 0 && rating <= 10 )
        {
            text = [text stringByAppendingFormat:@" (my rating: %d/10)", rating];
        }
        picker.body = text;
        
        if ( [MFMessageComposeViewController canSendAttachments] )
        {
            UIImage * image = [recipe  objectForKey:@"photo"];
            if ( image != nil )
            {
                NSData * imagedata = UIImageJPEGRepresentation( image, 0.8 );
                [picker addAttachmentData:imagedata typeIdentifier:@"image/jpeg" filename:@"photo.jpg"];
            }
        }
        [self presentViewController:picker animated:YES completion:nil];
    }
    else
    {
        [utils showUserMessage:LOC( @"The device is not configured to send messages." ) withTitle:LOC( @"Message Error" )];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    void (^completionHandler)(void) = ^()
    {
        [[self getGameScene] becomeFirstResponder];
    };
    // Notifies users about errors associated with the interface
    if ( result == MessageComposeResultFailed )
    {
        [utils showUserMessage:LOC( @"Unable to send Message." ) withTitle:LOC( @"Message Error" )];
    }
    [controller dismissViewControllerAnimated:YES completion:completionHandler];
}

-(void) onSendEmail:(NSDictionary *)recipe 
{
    if ( [MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController * controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;

        NSString * strRating = @"";
        int rating = [[recipe  objectForKey:@"userrating"] intValue];
        if ( rating > 0 && rating <= 10 )
        {
            strRating = [NSString stringWithFormat:@"My rating: %d/10", rating];
        }
        NSString * strNote = [recipe objectForKey:@"note"];
        if ( [strNote length] > 0 )
        {
            strNote = [NSString stringWithFormat:@"<b>Personal Note:</b></br><i>%@</i>", strNote];
        }
        else
        {
            strNote = @"";
        }
        NSString * url = @"http://www.phatware.com/shaker"; // TODO: change to the store URL
        
        // TODO: make localizable in the future...
        NSString * html = [NSString stringWithFormat:@"<html> <head>"
                           "<style type=\"text/css\">\nbody {font-family: \"Verdana\"; font-size: 17px;}\n-webkit-touch-callout: none;\n</style>"
                           "<style type=\"text/css\">\na {color:blue; text-decoration:none; font-size: 20px;}</style>"
                           "</head><body> <h2>%@</h2>"
                           "<p><b>Glass:</b></p> <ul><li>%@</ul></li> <p><b>Ingredients:</b></p><p> %@</p>"
                           "<p>%@</p> <p>%@</p> <p>%@</p> <p>Composed with <a href=\"%@\">Shaker</a> </p></body></html>",
                           [recipe  objectForKey:@"name"],
                           [recipe  objectForKey:@"glass"],
                           [recipe  objectForKey:@"ingredients"],
                           [recipe  objectForKey:@"instructions"], strRating, strNote, url];
        
        [controller setMessageBody:html isHTML:YES];
        [controller setSubject:[NSString stringWithFormat:@"Drinking \"%@\"", [recipe  objectForKey:@"name"]]];
        UIImage * image = [recipe  objectForKey:@"photo"];
        if ( image != nil )
        {
            NSData * imagedata = UIImageJPEGRepresentation( image, 0.8 );
            [controller addAttachmentData:imagedata mimeType:@"image/jpeg" fileName:@"photo.jpg"];
        }

        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        // show warning
        [utils showUserMessage:LOC( @"The device is not configured to send emails." ) withTitle:LOC( @"Email Error" )];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ( result == MFMailComposeResultFailed )
    {
        // show error message
        NSString * strAlert = [NSString stringWithFormat:NSLocalizedString( @"Unable to send Email: %@", @""),
                               error ? [error localizedDescription] : NSLocalizedString( @"Unknown Error.", @"" )];

        [utils showUserMessage:strAlert withTitle:LOC( @"Email Error" )];
    }
    
    void (^completionHandler)(void) = ^()
    {
        [[self getGameScene] becomeFirstResponder];
    };
    [controller dismissViewControllerAnimated:YES completion:completionHandler];
}

- (void) menuSelected:(NSString *)name
{
    BOOL showAd = NO;
    if ( [name isEqualToString:@"MAKE"] )
    {
        // show ingredients first
        self.game.coctails.gamefilter = kGameFilterCustom;

        CategoryViewController * categories = [[CategoryViewController alloc] initWithStyle:(UITableViewStylePlain)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:categories];
        categories.delegate = self;
        categories.database = self.game.coctails;
        
        // navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navigationController animated:YES completion:nil];
        
        return;
    }
    else if ( [name isEqualToString:@"UP"] || [name isEqualToString:@"DOWN"] )
    {
        FavoritesViewController * favorits = [[FavoritesViewController alloc] initWithStyle:(UITableViewStylePlain)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:favorits];
        favorits.database = self.game.coctails;
        favorits.recipesPresnetation = ([name isEqualToString:@"DOWN"]) ? kRecipeViewPresentationHate : kRecipeViewPresentationLike;
        // navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navigationController animated:YES completion:nil];
        return;
    }
    else if ( [name isEqualToString:@"BAR"] )
    {
        self.game.coctails.gamefilter = kGameFilterDefault;
        showAd = YES;
    }
    else if ( [name isEqualToString:@"TOP5"] )
    {
        self.game.coctails.gamefilter = kGameFilterTop5;
        showAd = YES;
    }
    else if ( [name isEqualToString:@"TOP10"] )
    {
        self.game.coctails.gamefilter = kGameFilterTop10;
        showAd = YES;
    }
    else if ( [name isEqualToString:@"NON"] )
    {
        self.game.coctails.gamefilter = kGameFilterFree;
        showAd = YES;
    }
    
    SKView * skView = (SKView *)self.view;
    SKTransition *reveal = [SKTransition doorsOpenHorizontalWithDuration:1.5];
    [skView presentScene:self.game transition:reveal];
    [self.game.shakeview becomeFirstResponder];

#ifdef GOOGLE_ADMOB
    if ( (![MKStoreManager featureDisableAdsPurchased]) && self.interstitial != NULL && showAd && play_count > 1 && arc4random_uniform(1000)%2 == 0 &&
        self.interstitial.isReady )
    {
        // TODO: check sound thread
        [self.interstitial presentFromRootViewController:self];
    }
#endif // GOOGLE_ADMOB
    
#ifdef GOOGLE_ANALYTICS
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id_Play_%@", name],
                                     kFIRParameterContentType:@"Game"
                                     }];
#endif // GOOGLE_ANALYTICS
}

- (void) categoryViewControllerPlayPressed
{
    self.game.coctails.gamefilter = kGameFilterCustom;

    SKView * skView = (SKView *)self.view;
    SKTransition *reveal = [SKTransition doorsOpenHorizontalWithDuration:1.5];
    [skView presentScene:self.game transition:reveal];
    [self.game.shakeview becomeFirstResponder];
}

- (void) showMainMenu
{
    SKView * skView = (SKView *)self.view;
    SKTransition *reveal = [SKTransition doorsCloseHorizontalWithDuration:1.5];
    [skView presentScene:self.menu transition:reveal];
    
#ifdef GOOGLE_ADMOB
    // TODO: show ad here
    if ( self.interstitial != NULL && ![MKStoreManager featureDisableAdsPurchased] && self.interstitial.isReady)
    {
        if ( arc4random_uniform(1000)%2 == 0 )
            [self.interstitial presentFromRootViewController:self];
    }
    else
    {
        NSLog(@"Ad wasn't ready");
    }
#endif // GOOGLE_ADMOB
}

#ifdef GOOGLE_ADMOB

- (GADInterstitial *)createAndLoadInterstitial
{
    if ( [MKStoreManager featureDisableAdsPurchased] )
        return NULL;
    GADInterstitial * interstitial = [[GADInterstitial alloc] initWithAdUnitID:ADMOB_MAINMENU_ID];
    interstitial.delegate = self;
    GADRequest * request = [GADRequest request];
    [interstitial loadRequest:request];
    return interstitial;
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    NSLog(@"interstitialDidReceiveAd");
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial
{
    self.interstitial = [self createAndLoadInterstitial];
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"interstitial:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

#endif // GOOGLE_ADMOB


- (void) buttonPressed:(UIButton *)button
{
    if ( button.tag == kMenuButtonRecipeList )
    {
        // show unlocked recipes
        RecipesViewController * recipes = [[RecipesViewController alloc] initWithStyle:(UITableViewStylePlain)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:recipes];
        
        recipes.database = self.game.coctails;
        
        // navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }
    if ( button.tag == kMenuButtonSettings )
    {
        // show settings
        OptionsViewController * options = [[OptionsViewController alloc] initWithStyle:(UITableViewStyleGrouped)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:options];
        
        // navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

@end
