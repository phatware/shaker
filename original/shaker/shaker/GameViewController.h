//
//  GameViewController.h
//  shaker
//

//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <iAd/iAd.h>
#import <MessageUI/MessageUI.h>

#import "GameScene.h"
#import "MenuScene.h"
#import "UIRatingView.h"
#import "UIShareView.h"
#import "UIShoppingView.h"
#import "UINoteView.h"
#import "CategoryViewController.h"

@interface GameViewController : UIViewController <// ADBannerViewDelegate,
                            GameSceneProtocl, UIRatingViewProtocol, MenuSceneProtocl,
                            UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIShareViewDelegate, UINoteViewDelegate,
                            MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIShoppingViewDelegate,
                            CategoryViewControllerDelegate>

@end
