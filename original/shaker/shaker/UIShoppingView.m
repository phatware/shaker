//
//  UIShoppingView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UIShoppingView.h"
#import "UIShareView.h"

#define BUTTON_GAP  20

@implementation UIShoppingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIImage *   image = [UIImage imageNamed:@"email"];
        CGRect      btnRect = CGRectMake( BUTTON_GAP, 10, image.size.width, image.size.height );
        
        UIButton * btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceMail;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onButtonDown:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:image forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);
        
        btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceMessage;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onButtonDown:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"message"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);
        
        btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = btnRect;
        btn.tag = kShareServiceCopy;
        btn.tintColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(onButtonDown:) forControlEvents:(UIControlEventTouchDown)];
        [btn setImage:[UIImage imageNamed:@"copy"] forState:(UIControlStateNormal)];
        [self addSubview:btn];
        btnRect.origin.x += (BUTTON_GAP + btnRect.size.width);

        frame.size.width = btnRect.origin.x;
        self.frame = frame;
        self.outlineColor = [UIColor colorWithRed:(175.0/255.0) green:1.0 blue:(175.0/255.0) alpha:1.0];
    }
    return self;
}

- (void) onButtonDown:(UIButton *)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSendShoppingList:using:)] )
    {
        [self.delegate onSendShoppingList:sender using:sender.tag];
    }
    
    [self dismissAnimated:YES];
}

@end
