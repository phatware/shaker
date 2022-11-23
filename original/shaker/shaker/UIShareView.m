//
//  UIShareView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UIShareView.h"
#import "utils.h"

#define BUTTON_GAP  15

@implementation UIShareView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIImage *   image = [UIImage imageNamed:@"email"];
        CGRect      btnRect = CGRectMake( BUTTON_GAP, 10, image.size.width, image.size.height );
        
        UIButton *  btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
#ifdef FB_SUPPORT
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceFacebook;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onFacebook:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"facebook"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);

#endif // FB_SUPPORT
#ifdef TWITTER_SUPPORT
        CGRect      btnRect = CGRectMake( BUTTON_GAP, 10, image.size.wid
        btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceTwitter;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onTweet:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"twitter"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);
#endif // TWITTER_SUPPORT
                                         
        btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceMail;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onSendEmail:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"email"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);
        
        btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceMessage;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onSendSMS:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"message"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);
        
        frame.size.width = btnRect.origin.x;
        self.frame = frame;
        self.outlineColor = [UIColor whiteColor];
    }
    return self;
}

- (void) onSendSMS:(UIButton *)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSendMessage:using:)] )
    {
        [self.delegate onSendMessage:sender using:sender.tag];
    }
    
    [self dismissAnimated:YES];
}

- (void) onSendEmail:(UIButton *)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSendMessage:using:)] )
    {
        [self.delegate onSendMessage:sender using:sender.tag];
    }

    [self dismissAnimated:YES];
}

- (void) onTweet:(UIButton *)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSendMessage:using:)] )
    {
        [self.delegate onSendMessage:sender using:sender.tag];
    }

    [self dismissAnimated:YES];
}

- (void) onFacebook:(UIButton *)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSendMessage:using:)] )
    {
        [self.delegate onSendMessage:sender using:sender.tag];
    }

    [self dismissAnimated:YES];
}

@end
