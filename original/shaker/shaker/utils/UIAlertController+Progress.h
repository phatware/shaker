//
//  UIAlertController+Progress.h
//  UIKitCategoryAdditions
//

#import <UIKit/UIKit.h>

#ifndef _WATCH_KIT

#define PROGRESSBAR_TAG1        10
#define PROGRESSBAR_TAG2        12


@interface UIAlertController (ProgressAlert)

+ (nullable instancetype) activityAlert:(nullable NSString *)strTitle withMessage:(nullable NSString *)strMessage;
+ (nullable instancetype) progressAlert:(nullable NSString *)strTitle withMessage:(nullable NSString *)strMessage;
+ (nullable instancetype) progressAlert2:(nullable NSString *)strTitle withMessage:(nullable NSString *)strMessage;

+ (nullable instancetype) progressAlert:(nullable NSString *)strTitle withMessage:(nullable NSString *)strMessage button:(nonnull NSString *)buttonTitle completion:(void (^ __nullable)(void))completion;

+ (void) showQuestion:(nullable NSString *)message withTitle:(nullable NSString *)title yesCompletion:(void (^ __nullable)(void))yesCompletion noCompletion:(void (^ __nullable)(void))noCompletion;
+ (void) showMessage:(nullable NSString *)message withTitle:(nullable NSString *)title;
+ (void) showMessage:(nullable NSString *)message withTitle:(nullable NSString *)title completion:(void (^ __nullable)(void))completion;
+ (void) showOkCancel:(nullable NSString *)message withTitle:(nullable NSString *)title okTitle:(nullable NSString *)okTitle okCompletion:(void (^ __nullable)(void))okCompletion cancelCompletion:(void (^ __nullable)(void))cancelCompletion;
+ (void) networkConnectionWarning;
+ (void) networkConnectionWarningWithSettings;

- (void) dismiss:(Boolean)animated;
- (void) show:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

#endif //

