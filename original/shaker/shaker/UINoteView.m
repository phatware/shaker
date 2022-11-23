//
//  UINoteView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UINoteView.h"
#import "utils.h"

#define GAP						10
#define kRowHeight				30
#define kButtonWidth			65
#define kButtonHeight           30
#define kButtonOffset           12
#define kAddButtonWidth			25

@interface UINoteView()
{
}

@end

@implementation UINoteView


- (UIButton *)buttonWithTitle:(NSString *)title
                       target:(id)target
                     selector:(SEL)selector
                        frame:(CGRect)frame
                darkTextColor:(BOOL)darkTextColor
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    // or you can do this:
    //		UIButton *button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    //		button.frame = frame;
    
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:self.tintColor forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    if ( darkTextColor )
        button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    else
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
    
    // in case the parent view draws with a custom color or gradient, use a transparent color
    button.backgroundColor = [UIColor clearColor];
    return button;
}

- (id)initWithFrame:(CGRect)frame initialText:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backColor = [UIColor whiteColor];
        self.outlineColor = [UIColor colorWithRed:(166.0/255.0) green:(213.0/255.0) blue:(246.0/255.0) alpha:1.0];
        self.titleColor = [UIColor blackColor];
        self.title = LOC( @"Note" );
        self.xArrow = -1;

        // create close button
        CGRect fr = CGRectMake( kButtonOffset, kButtonOffset, kButtonWidth, kButtonHeight );
        UIButton * closeButton = [self buttonWithTitle:NSLocalizedString( @"Cancel", @"" )
                                      target:self
                                    selector:@selector(actionClose:)
                                       frame:fr
                               darkTextColor:NO];
        [self addSubview:closeButton];
        
        
        fr = CGRectMake( frame.size.width - kButtonOffset - kButtonWidth, kButtonOffset, kButtonWidth, kButtonHeight );
        UIButton * okButton = [self buttonWithTitle:NSLocalizedString( @"Done", @"" )
                                   target:self
                                 selector:@selector(actionOK:)
                                    frame:fr
                            darkTextColor:YES];
        
        [self addSubview:okButton];
        
        fr = CGRectInset( self.clientRect, 7, 7 );
        UITextView * textView = [[UITextView alloc] initWithFrame:fr];
        textView.backgroundColor = [UIColor clearColor];
        textView.text = text;
        textView.delegate = self;
        textView.font = [UIFont fontWithName:@"Marker Felt" size:20];
        textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
        [self addSubview:textView];
        [textView becomeFirstResponder];
        self.textView = textView;
    }
    return self;
}

- (void) removeFromSuperview
{
    if ( self.textView )
    {
        [self.textView resignFirstResponder];
        self.textView = nil;
    }
    [super removeFromSuperview];
}

- (void) actionClose:(id)sender
{
    [self dismissAnimated:YES];
}

- (void) actionOK:(id)sender
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onSetNoteText:)] )
    {
        [self.delegate onSetNoteText:self.textView.text];
    }
    [self dismissAnimated:YES];
}

@end
