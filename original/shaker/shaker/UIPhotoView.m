//
//  UIPhotoView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/21/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UIPhotoView.h"

@interface UIPhotoView()
{
}

@end

@implementation UIPhotoView

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIImageView * photo = [[UIImageView alloc] initWithImage:image];
        photo.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat maxsize = frame.size.height;
        if ( image.size.width > image.size.height )
        {
            frame.size.width = maxsize;
            frame.size.height = (image.size.height * maxsize)/image.size.width;
        }
        else
        {
            frame.size.height = maxsize;
            frame.size.width = (image.size.width * maxsize)/image.size.height;
        }
        self.frame = frame;
        photo.frame = CGRectInset( self.bounds, 10, 10 );
        
        CGRect btnRect = CGRectMake( 20, frame.size.height, frame.size.width - 40, 38 );
        UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:NSLocalizedString( @"RETAKE PHOTO", @"" ) forState:(UIControlStateNormal)];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont fontWithName:@"Marker Felt" size:24];
        button.frame = btnRect;
        [button addTarget:self action:@selector(takePhoto:) forControlEvents:(UIControlEventTouchDown)];
        [self addSubview:button];
        
        frame.size.height += 50;
        self.frame = frame;
        photo.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        photo.userInteractionEnabled = NO;
        photo.backgroundColor = [UIColor clearColor];
        photo.opaque = NO;
        [self addSubview:photo];
        self.outlineColor = [UIColor colorWithRed:1.0 green:(182.0/255.0) blue:(182.0/255.0) alpha:1.0];
    }
    return self;
}

- (void) takePhoto:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:TAKE_PHOTO_NOTIFICATION object:self userInfo:nil];
    [self dismissAnimated:YES];
}


@end
