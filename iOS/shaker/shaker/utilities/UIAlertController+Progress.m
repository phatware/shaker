//
//  UIAlertController+Progress.m
//  UIKitCategoryAdditions
//


#import "UIAlertController+Progress.h"
#import <objc/runtime.h>

#define LOC(str)  NSLocalizedString( str, @"" )

@interface UIAlertController ()
@property (nonatomic, strong) UIWindow* alertWindow;
@end

@implementation UIAlertController (UIProgressAlert)

+ (void) networkConnectionWarning
{
    // show error message and quit
    [UIAlertController showMessage:LOC( @"Your device must be connected to Internet to perform this command.")
                         withTitle:LOC( @"No Internet Connection")
                      withSettings:NO];
}

+ (void) networkConnectionWarningWithSettings
{
    UIAlertController * alert = [UIAlertController
                                alertControllerWithTitle:LOC( @"No Internet Connection")
                                message:LOC( @"Your device must be connected to Internet to perform this command.")
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* settings = [UIAlertAction
                               actionWithTitle:LOC( @"Settings" )
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   // [utils openNetworkSettings];
                               }];
    [alert addAction:settings];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                         }];

    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert addAction:ok];
    [alert show:YES completion:nil];
}

+ (void) showQuestion:(NSString *)message withTitle:(NSString *)title yesCompletion:(void (^ __nullable)(void))yesCompletion noCompletion:(void (^ __nullable)(void))noCompletion
{
    UIAlertController * alert= [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yes = [UIAlertAction actionWithTitle:LOC( @"Yes" ) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
     {
         if ( yesCompletion )
             yesCompletion();
     }];
    [alert addAction:yes];
    
    UIAlertAction* no = [UIAlertAction actionWithTitle:LOC( @"No" ) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
      {
          if ( noCompletion )
              noCompletion();
      }];
    
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert addAction:no];
    [alert show:YES completion:nil];
}


+ (void) showOkCancel:(NSString *)message withTitle:(NSString *)title okTitle:(NSString *)okTitle okCompletion:(void (^ __nullable)(void))okCompletion cancelCompletion:(void (^ __nullable)(void))cancelCompletion
{
    UIAlertController * alert= [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];

    NSString * t = (okTitle == nil) ? @"OK" : okTitle;
    UIAlertAction* yes = [UIAlertAction actionWithTitle:t style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                          {
                              if ( okCompletion )
                                  okCompletion();
                          }];
    [alert addAction:yes];

    UIAlertAction* no = [UIAlertAction actionWithTitle:LOC( @"Cancel" ) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
                         {
                            if ( cancelCompletion )
                                 cancelCompletion();
                         }];
    
    // alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert addAction:no];
    [alert show:YES completion:nil];
}

+ (void) showMessage:(NSString *)message withTitle:(NSString *)title withSettings:(BOOL)showSettings
{
    UIAlertController * alert= [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
    }];
    
    if (showSettings)
    {
        UIAlertAction* settings = [UIAlertAction
                             actionWithTitle:LOC(@"Settings")
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if (nil != url)
            {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    
                }];
            }
        }];
        [alert addAction:settings];
    }

    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert addAction:ok];
    [alert show:YES completion:nil];
}

+ (void) showMessage:(NSString *)message withTitle:(NSString *)title completion:(void (^ __nullable)(void))completion
{
    UIAlertController * alert= [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             if ( completion != nil )
                             {
                                 completion();
                             }
                         }];
    
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert addAction:ok];
    [alert show:YES completion:nil];
}

+ (nullable instancetype) activityAlert:(NSString *)strTitle withMessage:(NSString *)strMessage
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:strTitle
                                                                    message:strMessage
                                                             preferredStyle:(UIAlertControllerStyleAlert)];
    
    if ( alert == nil )
        return nil;
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(121.5f, 80.0, 37.0f, 37.0f)];
    if (@available(iOS 13.0, *)) {
        [activityView setActivityIndicatorViewStyle: UIActivityIndicatorViewStyleLarge];
    } else {
        // Fallback on earlier versions
    }
    [activityView startAnimating];
    // activityView.color = [UIColor getCurrentTintColor];
    [alert.view addSubview:activityView];
    
    alert.view.clipsToBounds = YES;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:alert.view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:126.0];
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert.view addConstraint:constraint];
    [alert show:YES completion:nil];
    return alert;
}

+ (nullable instancetype) progressAlert:(NSString *)strTitle withMessage:(NSString *)strMessage
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:strTitle
                                                                    message:strMessage
                                                             preferredStyle:(UIAlertControllerStyleAlert)];
    
    if ( alert== nil )
        return nil;
    
    UIProgressView *progbar = [[UIProgressView alloc] initWithFrame:CGRectMake(40.0f, 90.0f, 200.0f, 20.0f)];
    progbar.tag = PROGRESSBAR_TAG1;
    [progbar setProgressViewStyle: UIProgressViewStyleDefault];
    //progbar.tintColor = [UIColor getCurrentTintColor];
    [alert.view addSubview:progbar];
    
    alert.view.clipsToBounds = YES;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:alert.view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:112.0];
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert.view addConstraint:constraint];
    [alert show:YES completion:nil];
    return alert;
}

+ (nullable instancetype) progressAlert:(NSString *)strTitle withMessage:(NSString *)strMessage button:(NSString *)buttonTitle completion:(void (^)(void))completion
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:strTitle
                                                                    message:strMessage
                                                             preferredStyle:(UIAlertControllerStyleAlert)];

    if ( alert== nil )
        return nil;

    UIProgressView *progbar = [[UIProgressView alloc] initWithFrame:CGRectMake(40.0f, 90.0f, 200.0f, 20.0f)];
    progbar.tag = PROGRESSBAR_TAG1;
    [progbar setProgressViewStyle: UIProgressViewStyleDefault];
    //progbar.tintColor = [UIColor getCurrentTintColor];
    [alert.view addSubview:progbar];
    alert.view.clipsToBounds = YES;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:alert.view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:112.0];
    [alert.view addConstraint:constraint];

    UIAlertAction * button = [UIAlertAction
                         actionWithTitle:buttonTitle
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             if ( completion != nil )
                             {
                                 completion();
                             }
                         }];
    
    [alert addAction:button];
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert show:YES completion:nil];
    return alert;
}

+ (nullable instancetype) progressAlert2:(NSString *)strTitle withMessage:(NSString *)strMessage
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:strTitle
                                                                    message:strMessage
                                                             preferredStyle:(UIAlertControllerStyleAlert)];
    
    if ( alert== nil )
        return nil;
    
    UIProgressView *progbar = [[UIProgressView alloc] initWithFrame:CGRectMake(40.0f, 90.0f, 200.0f, 10.0f)];
    progbar.tag = PROGRESSBAR_TAG1;
    [progbar setProgressViewStyle: UIProgressViewStyleDefault];
    //progbar.tintColor = [UIColor getCurrentTintColor];
    [alert.view addSubview:progbar];
    
    progbar = [[UIProgressView alloc] initWithFrame:CGRectMake(40.0f, 110.0f, 200.0f, 10.0f)];
    progbar.tag = PROGRESSBAR_TAG2;
    [progbar setProgressViewStyle: UIProgressViewStyleDefault];
    //progbar.tintColor = [UIColor getCurrentTintColor];
    [alert.view addSubview:progbar];
    
    alert.view.clipsToBounds = YES;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:alert.view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:132.0];
    [alert.view addConstraint:constraint];
    //alert.view.tintColor = [UIColor getCurrentTintColor];
    [alert show:YES completion:nil];
    return alert;
}

- (void) dismiss:(Boolean)animated
{
    [self dismissViewControllerAnimated:animated completion:nil];
}

- (void) show:(BOOL)animated completion:(void (^ __nullable)(void))completion
{
    self.alertWindow = [self window];
    [self.alertWindow makeKeyAndVisible];
    [self.alertWindow.rootViewController presentViewController: self animated: animated completion: completion];
}

- (void)setAlertWindow: (UIWindow*)alertWindow
{
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow*)alertWindow
{
    return objc_getAssociatedObject(self, @selector(alertWindow));
}


- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}

- (UIWindow *) window
{
    UIWindow * win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController * vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    win.rootViewController = vc;
    win.backgroundColor = [UIColor clearColor];
    win.windowLevel = UIWindowLevelAlert + 1;
#if __has_feature(objc_arc)
    return win;
#else
    [vc autorelease];
    return [win autorelease];
#endif
}


@end
