//
//  UIShareView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"

typedef enum
{
#ifdef FB_SUPPORT
    kShareServiceFacebook,
#endif // FB_SUPPORT
#ifdef TWITTER_SUPPORT
    kShareServiceTwitter,
#endif // TWITTER_SUPPORT
    kShareServiceMail,
    kShareServiceMessage,
    kShareServiceCopy,
} kShareServices;


@protocol UIShareViewDelegate <NSObject>

- (void) onSendMessage:(UIButton *)sender using:(NSInteger)service;

@end


@interface UIShareView : UICustomPopupView

@property (nonatomic, weak) id<UIShareViewDelegate> delegate;

@end
