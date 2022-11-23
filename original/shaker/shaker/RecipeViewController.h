//
//  RecipeViewController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/24/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <WebKit/WebKit.h>

#import "CoctailsDatabase.h"
#import "UIRatingView.h"
#import "UINoteView.h"

@protocol RecipeViewControllerDeleagte <NSObject>
@optional
- (void) ratingChanged:(int)newrating;
@end

@interface RecipeViewController : UIViewController <WKNavigationDelegate, MFMailComposeViewControllerDelegate, UIRatingViewProtocol, UINoteViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSDictionary * recipe;
@property (nonatomic, strong) CoctailsDatabase * database;
@property (nonatomic, weak) id<RecipeViewControllerDeleagte> delegate;

@end
