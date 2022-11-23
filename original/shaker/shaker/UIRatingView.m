//
//  UIRatingView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/20/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UIRatingView.h"

@interface UIRatingView()

@property (nonatomic, strong) UIImage * star1;
@property (nonatomic, strong) UIImage * star2;

@end

@implementation UIRatingView


#define MAX_STAR_RATING     10
#define X_GAP               4.0


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.star1 = [UIImage imageNamed:@"star_yellow"];
        self.star2 = [UIImage imageNamed:@"star_gray"];
        self.outlineColor = [UIColor colorWithRed:(250.0/255.0) green:(243.0/255.0) blue:(131.0/255.0) alpha:1.0];
    }
    return self;
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGFloat gap = ((self.clientRect.size.width - 2 * X_GAP) - (self.star1.size.width*MAX_STAR_RATING))/(MAX_STAR_RATING-1);
    if ( gap < 1.0 )
        gap = 1.0;
    CGRect rStar = CGRectMake( self.clientRect.origin.x + X_GAP, (self.clientRect.size.height - self.star1.size.height)/2.0 + 3.0,
                              self.star1.size.width, self.star1.size.height );
    for ( int i = 0; i < MAX_STAR_RATING; i++ )
    {
        if ( i < self.rating )
        {
            [self.star1 drawInRect:rStar];
        }
        else
        {
            [self.star2 drawInRect:rStar];
        }
        rStar.origin.x += (rStar.size.width + gap);
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch*	touch = [[event touchesForView:self] anyObject];
    CGPoint		location = [touch locationInView:self];
    
    [self processEventAtLocation:location event:UIControlEventTouchDown];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch*	touch = [[event touchesForView:self] anyObject];
    CGPoint		location = [touch locationInView:self];
    
    [self processEventAtLocation:location event:UIControlEventTouchDragEnter];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch*	touch = [[event touchesForView:self] anyObject];
    CGPoint		location = [touch locationInView:self];
    
    [self processEventAtLocation:location event:UIControlEventTouchDragExit];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch*	touch = [[event touchesForView:self] anyObject];
    CGPoint		location = [touch locationInView:self];
    
    [self processEventAtLocation:location event:UIControlEventTouchCancel];
}

- (void) processEventAtLocation:(CGPoint)location event:(UIControlEvents)event
{
    CGFloat gap = ((self.clientRect.size.width - 2 * X_GAP) - (self.star1.size.width*MAX_STAR_RATING))/(MAX_STAR_RATING-1);
    if ( gap < 1.0 )
        gap = 1.0;
    CGRect rStar = CGRectMake( self.clientRect.origin.x + X_GAP, (self.clientRect.size.height - self.star1.size.height)/2.0 + 3.0,
                              self.star1.size.width, self.star1.size.height );
    
    for ( int i = 0; i < MAX_STAR_RATING; i++ )
    {
        if ( CGRectContainsPoint( rStar, location ) )
        {
            if ( self.rating != i+1 )
            {
                self.rating = i + 1;
                [self setNeedsDisplay];
            }
            break;
        }
        rStar.origin.x += (rStar.size.width + gap);
    }
    if ( event == UIControlEventTouchDragExit )
    {
        // notify paret about new rating and close the view
        if ( self.delegate && [self.delegate respondsToSelector:@selector(ratingView:rating:)] )
        {
            if ( [self.delegate ratingView:self rating:self.rating] )
            {
                [self dismissAnimated:YES];
            }
        }
    }
}

@end
