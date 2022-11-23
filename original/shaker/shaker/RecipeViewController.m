//
//  RecipeViewController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/24/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "RecipeViewController.h"
#import "utils.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS

@interface RecipeViewController ()

@property (nonatomic, strong ) WKWebView * webview;

@end


@implementation RecipeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    sqlite3_int64 recid = [[self.recipe  objectForKey:@"userrecord_id"] longLongValue];
    if ( recid > 0)
    {
        NSArray* toolbarItems = [NSArray arrayWithObjects:
                                 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                                 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera"] style:(UIBarButtonItemStylePlain) target:self action:@selector(takePicture:)],
                                 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                                 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star"] style:(UIBarButtonItemStylePlain) target:self action:@selector(changeRating:)],
                                 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                                 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"document"] style:(UIBarButtonItemStylePlain) target:self action:@selector(textNote:)],
                                 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
                                 nil];
        self.toolbarItems = toolbarItems;
        // self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationController.view.backgroundColor = [UIColor whiteColor];
    }
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    theConfiguration.dataDetectorTypes = WKDataDetectorTypeNone;
    self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webview.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.webview.autoresizesSubviews = YES;
    self.webview.navigationDelegate = self;
    self.webview.backgroundColor = [UIColor whiteColor];
    self.webview.opaque = NO;
    
    [self.webview loadHTMLString:[self htmlString:@""] baseURL:nil];
    [self.view addSubview:self.webview];
    
    UIBarButtonItem * emailButton = [[UIBarButtonItem alloc] initWithTitle:LOC( @"Email" ) style:(UIBarButtonItemStylePlain) target:self action:@selector(email:)];
    self.navigationItem.rightBarButtonItem = emailButton;
    self.title = LOC( @"Recipe" );
}

#pragma mark -- Photo

- (void) takePicture:(id)sender
{
    UIImage * image = [self.recipe objectForKey:@"photo"];
    if ( image == nil )
    {
        [self insertImageDialog:UIImagePickerControllerSourceTypeCamera];
    }
    else
    {
        // ask to retake the photo
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:LOC( @"Photo")
                                     message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction* takePhoto = [UIAlertAction
                                   actionWithTitle:LOC( @"Retake Photo" )
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [self insertImageDialog:UIImagePickerControllerSourceTypeCamera];
                                   }];
        [alert addAction:takePhoto];

        UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                             }];
        
        [alert addAction:cancel];
        [alert show:YES completion:nil];
    }
}

- (void) insertImageDialog:(UIImagePickerControllerSourceType)sourceType
{
    
    if ( ![UIImagePickerController isSourceTypeAvailable:sourceType] )
    {
        [utils showUserMessage:LOC( @"Camera is unavailable." ) withTitle:LOC( @"Camera Error" )];
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

    sqlite3_int64 recid = [[self.recipe  objectForKey:@"userrecord_id"] longLongValue];
    if ( recid > 0 )
    {
        if ( [self.database updateUserPhoto:image record:recid] )
        {
            NSMutableDictionary * recipe  = [self.recipe  mutableCopy];
            [recipe  setObject:image forKey:@"photo"];
            self.recipe  = [recipe  copy];
            [self.webview loadHTMLString:[self htmlString:@""] baseURL:nil];
        }
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark -- Rating

- (void) changeRating:(id)sender
{
    CGRect frame = CGRectMake( 0.0, 0.0, (self.view.bounds.size.width - 20), 60 );
    UIRatingView * ratingview = [[UIRatingView alloc] initWithFrame:frame];
    ratingview.rating = [[self.recipe objectForKey:@"userrating"] intValue];
    ratingview.userRating = YES;
    ratingview.bottomArrow = YES;
    ratingview.delegate = self;
    if ( ratingview.rating < 1 )
    {
        ratingview.rating = [[self.recipe objectForKey:@"rating"] intValue];
        ratingview.userRating = NO;
    }
    CGPoint point = CGPointMake( 0, 0 );
    UIView *v = [sender valueForKey:@"view"];
    if( v )
    {
        CGRect r = [v.superview convertRect:v.frame toView:self.view];
        point = CGPointMake(CGRectGetMidX( r ), CGRectGetMaxY( r ));
        point.y -= 44;
    }
    ratingview.backColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    ratingview.outlineColor = self.navigationController.toolbar.tintColor;
    
    [ratingview presentInView:self.view fromPoint:point animated:YES];
}

- (BOOL) ratingView:(UIRatingView *)view rating:(int)rating
{
    sqlite3_int64 recid = [[self.recipe objectForKey:@"userrecord_id"] longLongValue];
    BOOL    result = NO;
    if ( recid > 0 )
    {
        if ( [[self.recipe objectForKey:@"userrating"] intValue] != rating )
        {
            if ( self.delegate && [self.delegate respondsToSelector:@selector(ratingChanged:)] )
            {
                [self.delegate ratingChanged:rating];
            }
        }
        result = [self.database updateUserRecord:recid note:[self.recipe objectForKey:@"note"] rating:rating visible:YES];
        if ( result )
        {
            NSMutableDictionary * recipe  = [self.recipe  mutableCopy];
            [recipe  setObject:[NSNumber numberWithInt:rating] forKey:@"userrating"];
            self.recipe  = [recipe  copy];
            [self.webview loadHTMLString:[self htmlString:@""] baseURL:nil];
        }
    }
    return YES;
}

#pragma mark -- Text Note

- (void) textNote:(id)sender
{
    CGFloat y = (self.view.frame.size.width > 350.0) ? 100.0 : 50.0;
    CGFloat h = (self.view.frame.size.width > 350.0) ? 250.0 : 210.0;
    CGRect frame = CGRectMake( 30.0/2.0, y, (self.view.bounds.size.width - 30.0), h );
    UINoteView * noteView = [[UINoteView alloc] initWithFrame:frame initialText:[self.recipe objectForKey:@"note"]];
    noteView.bottomArrow = NO;
    noteView.yOffset = y;
    noteView.delegate = self;
    CGPoint pos = CGPointZero;
    noteView.outlineColor = self.navigationController.toolbar.tintColor;
    noteView.titleBackColor = [UIColor colorWithWhite:0.95 alpha:0.98];
    [noteView presentInView:self.view fromPoint:pos animated:YES];
}

- (void) onSetNoteText:(NSString *)text
{
    if ( [text length] > 0 )
    {
        sqlite3_int64 recid = [[self.recipe  objectForKey:@"userrecord_id"] longLongValue];
        if ( [self.database updateUserRecord:recid note:text rating:[[self.recipe  objectForKey:@"userrating"] intValue] visible:YES] )
        {
            NSMutableDictionary * recipe  = [self.recipe  mutableCopy];
            [recipe  setObject:text forKey:@"note"];
            self.recipe  = [recipe  copy];
            [self.webview loadHTMLString:[self htmlString:@""] baseURL:nil];
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
    // TODO: fix color
}

//- (void) viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//
//    sqlite3_int64 recid = [[self.recipe  objectForKey:@"userrecord_id"] longLongValue];
//    if ( recid > 0)
//        self.navigationController.toolbarHidden = NO;
//}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    sqlite3_int64 recid = [[self.recipe  objectForKey:@"userrecord_id"] longLongValue];
    if ( recid > 0)
        self.navigationController.toolbarHidden = NO;
}

- (NSString *) htmlString:(NSString *)strFootnote
{
    NSString * strRating = @"";
    NSLog( @"%@", self.recipe );
    int rating = [[self.recipe  objectForKey:@"userrating"] intValue];
    if ( rating > 0 && rating <= 10 )
    {
        NSString * yellowstar = [utils imagesWithBase64:[UIImage imageNamed:@"star_yellow"]];
        NSString * graystar = [utils imagesWithBase64:[UIImage imageNamed:@"star_gray"]];
        strRating = @"<b>Rating:</b></p><p> ";
        int i = 0;
        for ( ; i < rating; i++ )
        {
            strRating = [strRating stringByAppendingFormat:@"<img src=\"%@\" width=\"30\" height=\"30\">", yellowstar];
        }
        for ( ; i < 10; i++ )
        {
            strRating = [strRating stringByAppendingFormat:@"<img src=\"%@\" width=\"30\" height=\"30\">", graystar];
        }
    }
    NSString * strNote = [self.recipe objectForKey:@"note"];
    if ( [strNote length] > 0 )
    {
        strNote = [NSString stringWithFormat:@"<b>Personal Note:</b></br><i>%@</i>", strNote];
    }
    else
    {
        strNote = @"";
    }
    
    NSString * strImage = @"";
    UIImage * image = [self.recipe objectForKey:@"photo"];
    if ( image != nil )
    {
        strImage = [utils imagesWithBase64:image];
        if ( strImage == nil )
            strImage = @"";
        else
        {
            int size = MIN( self.view.bounds.size.width, self.view.bounds.size.height );
            size -= 20;
            strImage = [NSString stringWithFormat:@"<p align=\"center\"><img src=\"%@\" width=\"%d\" height=\"%d\"></p>", strImage, size, size];
        }
    }
    
    // TODO: make localizable in the future...
    NSString * html = [NSString stringWithFormat:@"<html> <head>"
                       "<style type=\"text/css\">\nbody {font-family: \"Verdana\"; font-size: 36px;}\n-webkit-touch-callout: none;\n</style>"
                       "<style type=\"text/css\">\na {color:blue; text-decoration:none; font-size: 42px;}</style>"
                       "</head><body> <h3>%@</h3>"
                       "<p><b>Glass:</b></p> <ul><li>%@</ul></li> <p><b>Ingredients:</b></p><p> %@</p>"
                       "<p><b>Instructions:</b></p><p>%@</p> <p><b>Shopping list:</b></p><p>%@</p> %@ <p>%@</p> <p>%@</p> </p> %@ </body></html>",
                       [self.recipe  objectForKey:@"name"],
                       [self.recipe  objectForKey:@"glass"],
                       [self.recipe  objectForKey:@"ingredients"],
                       [self.recipe  objectForKey:@"instructions"],
                       [self.recipe  objectForKey:@"shopping"],
                       strImage, strRating, strNote, strFootnote];

    return html;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)webView:(WKWebView *)inView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeOther)
        decisionHandler(WKNavigationActionPolicyAllow);
    else
        decisionHandler(WKNavigationActionPolicyCancel);
}

- (void) email:(id)sender
{
    if ( [MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController * controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        
        NSString * footnote = @"<p>Composed with <a href=\"http://www.phatware.com/shaker\">Shaker</a> </p>";
        [controller setMessageBody:[self htmlString:footnote] isHTML:YES];
        [controller setSubject:[NSString stringWithFormat:@"\"%@\" Recipe", [self.recipe  objectForKey:@"name"]]];

        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        // show warning
        [utils showUserMessage:LOC( @"The device is not configured to send emails." ) withTitle:LOC( @"Email Error" )];
    }
#ifdef GOOGLE_ANALYTICS
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:@"id_SendEmail",
                                     kFIRParameterContentType:@"Game"
                                     }];
#endif // GOOGLE_ANALYTICS
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
    };
    [controller dismissViewControllerAnimated:YES completion:completionHandler];
}

@end
