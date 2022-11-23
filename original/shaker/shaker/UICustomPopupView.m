//
//  UICustomPopupView.m
//  Shaker
//
//  Created by Stanislav Miasnikov on 1/27/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"
// #import "utils.h"
// #import "UIConst.h"

@interface UITouchView : UIView

@property (nonatomic, assign) UICustomPopupView * popupview;

@end


@implementation UITouchView

@synthesize popupview;

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( self.popupview == nil )
        return;
    
    //UITouch*	touch = [[event touchesForView:self] anyObject];
	//CGPoint		location = [touch locationInView:self];
    // if ( CGRectContainsPoint( popupview.frame, location ) )
    {
        // Hide this view if clicked anywhere outsize
        [self.popupview dismissAnimated:YES];
        self.popupview = nil;
    }
}

@end


@interface UICustomPopupView()
{
    NSTimer * _timer;
}

@end

@implementation UICustomPopupView

@synthesize bottomArrow;
@synthesize xArrow;

#define ARROW_HEIGHT    10.0
#define RADIOUS         8.0
#define kToolbarHeight  44

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth );
        self.autoresizesSubviews = NO;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        self.userInteractionEnabled = YES;
        self.bottomArrow = NO;
        self.xArrow = -1;
        self.yOffset = 0;
        self.backColor = [UIColor colorWithRed:66.0/255.0 green:66.0/255.0 blue:66.0/255.0 alpha:0.92];
        self.titleColor = [UIColor colorWithRed:(59.0/255.0) green:(139.0/255.0) blue:(253.0/255.0) alpha:1.0];
        self.outlineColor = [UIColor blackColor];
        self.titleBackColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        self.title = nil;
        _timer = nil;
    }
    return self;
}

- (void) hidePopover
{
    [self dismissAnimated:YES];
}

- (void) dealloc
{
    self.title = nil;
    self.backColor = nil;
    self.outlineColor = nil;
    self.titleColor = nil;
    [self killAutodismissTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (CGRect) clientRect
{
    CGRect rect = self.bounds;
    rect = CGRectInset( rect, RADIOUS/2.0, RADIOUS/2.0 );
    if ( self.xArrow > 0 )
    {
        if ( ! self.bottomArrow )
            rect.origin.y += ARROW_HEIGHT;
        rect.size.height -= ARROW_HEIGHT;
    }
    if ( self.title != nil )
    {
        rect.origin.y += kToolbarHeight;
        rect.size.height -= kToolbarHeight;
    }
    return rect;
}

- (void) drawRect:(CGRect)rect
{
    // Drawing code
    // Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState( context );
	
    // draw the writing panel
	CGContextSetLineWidth( context, 0.5 );
	
	// As a bonus, we'll combine arcs to create a round rectangle!
    
	// 2. draw the input panel
	
	// Drawing with a dark stroke color
	CGContextSetStrokeColorWithColor(context, self.outlineColor.CGColor );
    CGContextSetFillColorWithColor(context, self.backColor.CGColor );
    
	CGRect rrect = rect;
	// If you were making this as a routine, you would probably accept a rectangle
	// that defines its bounds, and a radius reflecting the "rounded-ness" of the rectangle.
	CGFloat radius = RADIOUS;
	rrect.origin.x += 1;
	rrect.size.width -= 2;
    
    if ( self.xArrow <= 0 )
    {
        rrect.origin.y += 1;
        rrect.size.height -= 2;
    }
    else
    {
        rrect.origin.y = self.bottomArrow ? 1 : ARROW_HEIGHT + 1;
        rrect.size.height -= (ARROW_HEIGHT + 2);
    }

	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
    
    if ( self.xArrow <= 0 )
    {
        if ( self.title != nil )
        {
            midy = kToolbarHeight+5;
            CGContextSetFillColorWithColor(context, self.titleBackColor.CGColor );
            
            CGContextMoveToPoint(context, minx, midy);
            // Add an arc through 2 to 3
            CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
            // Add an arc through 4 to 5
            CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);

            CGContextAddLineToPoint(context, maxx, midy);
            CGContextAddLineToPoint(context, minx, midy);
            CGContextClosePath(context);
            CGContextDrawPath(context, kCGPathFillStroke);

            CGContextSetFillColorWithColor(context, self.backColor.CGColor );
            
            CGContextMoveToPoint(context, maxx, midy);
            // Add an arc through 6 to 7
            CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
            // Add an arc through 8 to 9
            CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
            // Close the path
            CGContextAddLineToPoint(context, minx, midy);
            CGContextAddLineToPoint(context, maxx, midy);
            CGContextClosePath(context);
            // Fill & stroke the path
            CGContextDrawPath(context, kCGPathFillStroke);
        }
        else
        {
            // No arrow
            // Start at 1
            CGContextMoveToPoint(context, minx, midy);
            // Add an arc through 2 to 3
            CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
            // Add an arc through 4 to 5
            CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
            // Add an arc through 6 to 7
            CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
            // Add an arc through 8 to 9
            CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
            // Close the path
            CGContextClosePath(context);
            // Fill & stroke the path
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    else
    {
        if ( self.title != nil )
        {
            midy = kToolbarHeight+5;
            CGContextSetFillColorWithColor(context, self.titleBackColor.CGColor );
        }

        if ( self.xArrow < RADIOUS + ARROW_HEIGHT )
            self.xArrow = RADIOUS + ARROW_HEIGHT;
        else if ( self.xArrow > rrect.size.width - (RADIOUS + ARROW_HEIGHT) )
        {
            self.xArrow = rrect.size.width - (RADIOUS + ARROW_HEIGHT);
        }
        if ( ! self.bottomArrow )
        {
            if ( midx >= self.xArrow - ARROW_HEIGHT )
                midx = self.xArrow - ARROW_HEIGHT - 5;
        }
        else
        {
            if ( midx <= self.xArrow + ARROW_HEIGHT )
                midx = self.xArrow + ARROW_HEIGHT + 5;
        }
        // Start at 1
        CGContextMoveToPoint(context, minx, midy);
        // Add an arc through 2 to 3
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);

        if ( ! self.bottomArrow )
        {
            CGContextAddLineToPoint( context, self.xArrow - ARROW_HEIGHT, miny );
            CGContextAddLineToPoint( context, self.xArrow, 1.0 );
            CGContextAddLineToPoint( context, self.xArrow + ARROW_HEIGHT, miny );
        }
        // Add an arc through 4 to 5
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);

        if ( self.title != nil )
        {
            CGContextAddLineToPoint(context, maxx, midy);
            CGContextAddLineToPoint(context, minx, midy);
            CGContextClosePath(context);
            CGContextDrawPath(context, kCGPathFillStroke);
            CGContextSetFillColorWithColor(context, self.backColor.CGColor );
            CGContextMoveToPoint(context, maxx, midy);
        }
        
        // Add an arc through 6 to 7
        CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);

        if ( self.bottomArrow )
        {
            CGContextAddLineToPoint( context, self.xArrow + ARROW_HEIGHT, maxy );
            CGContextAddLineToPoint( context, self.xArrow, maxy + ARROW_HEIGHT );
            CGContextAddLineToPoint( context, self.xArrow - ARROW_HEIGHT, maxy );
            // midx = self.xArrow - ARROW_HEIGHT;
        }

        // Add an arc through 8 to 9
        CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);

        if ( self.title != nil )
        {
            // Close the path
            CGContextAddLineToPoint(context, minx, midy);
            CGContextAddLineToPoint(context, maxx, midy);
        }
        CGContextClosePath(context);
        // Fill & stroke the path
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    if ( self.title != nil )
    {
        CGRect rTitle = CGRectMake( 0, 13, maxx, midy );
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary * attrib = @{ NSFontAttributeName: [UIFont systemFontOfSize:20.0], NSParagraphStyleAttributeName: paragraphStyle,
                                   NSForegroundColorAttributeName: self.titleColor };
        [self.title drawInRect:rTitle withAttributes:attrib];
#if !__has_feature(objc_arc)
        [paragraphStyle release];
#endif
    }
}

- (void) adjustPositionToPoint:(CGPoint)point
{
    CGRect f = self.frame;
    
    f.size = [self contentSizeForViewInPopoverView];
    
    if ( ! CGPointEqualToPoint( point, CGPointZero ) )
    {
        f.origin.y = point.y;
        f = CGRectInset( f, - RADIOUS/2.0, - RADIOUS/2.0 );
        f.size.height += ARROW_HEIGHT;
        f.origin.x = (self.superview.superview.bounds.size.width - f.size.width)/2.0;
        if ( f.origin.x > point.x )
        {
            f.origin.x = point.x - RADIOUS * 4.0;
        }
        else if ( f.origin.x + f.size.width < point.x )
        {
            f.origin.x = point.x - (f.size.width - RADIOUS * 4.0);
        }
        self.xArrow = point.x - f.origin.x;
    }
    else
    {
        f.origin.x = (self.superview.superview.bounds.size.width - f.size.width)/2.0;
        f.origin.y = (self.yOffset > 1 ) ? self.yOffset : (self.superview.superview.bounds.size.height - f.size.height)/2.0; // 30
        self.xArrow = -1;
    }
    self.frame = f;
}

- (void) popupInView:(UIView *)view fromPoint:(CGPoint)point
{
    CGRect f = self.frame;
    f.size = [self contentSizeForViewInPopoverView];
    
    f.origin.y = point.y - f.size.height;
    f.origin.x = (view.frame.size.width - f.size.width)/2.0;
    self.frame = f;
    self.xArrow = point.x;
    
    self.bottomArrow = YES;
    self.hidden = NO;
    self.alpha = 1.0;
    if ( self.superview == nil || [self.superview isEqual:view] )
    {
        self.contentMode = UIViewContentModeRedraw;
        [self removeFromSuperview];
        [view addSubview:self];
    }
    [self setNeedsDisplay];
}

- (void) showInView:(UIView * )view fromPoint:(CGPoint)point animated:(BOOL)animated autodismiss:(NSTimeInterval)timeinterval
{
    CGRect f = self.frame;
    f.size = [self contentSizeForViewInPopoverView];
    
    if ( ! CGPointEqualToPoint( point, CGPointZero ) )
    {
        f.origin.y = point.y - f.size.height;
        if (f.origin.x < 1.0 )
            f.origin.x = (view.frame.size.width - f.size.width)/2.0;
        self.frame = f;
        self.xArrow = point.x;
    }
    else
    {
        if (f.origin.x < 1.0 )
            f.origin.x = (view.frame.size.width - f.size.width)/2.0;
        f.origin.y = (self.yOffset > 1 ) ? self.yOffset : (view.bounds.size.height - f.size.height)/2.0; // 30
        self.xArrow = -1;
    }
    self.frame = f;
    self.hidden = NO;
    self.alpha = 1.0;
    [self setNeedsDisplay];
    
    if ( self.superview == nil || [self.superview isEqual:view] )
    {
        self.contentMode = UIViewContentModeRedraw;
        [self removeFromSuperview];
        [view addSubview:self];
        
        if ( animated )
        {
            self.alpha = 0.0;
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 self.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                             }
             ];
        }
    }

    [self killAutodismissTimer];
    if ( timeinterval > 0.0 )
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeinterval target:self
                                                selector:@selector(autodismiss:) userInfo:nil repeats:NO];
    }
}

- (void) killAutodismissTimer
{
    if ( nil != _timer )
    {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) autodismiss:(NSTimer *)timer
{
    [self dismissAnimated:NO];
}


- (void) presentInView:(UIView * )view fromPoint:(CGPoint)point animated:(BOOL)animated
{
    CGRect f = self.frame;
    
    UITouchView * backView = [[UITouchView alloc] initWithFrame:view.bounds];
    backView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    backView.autoresizesSubviews = YES;
    backView.popupview = self;
    backView.backgroundColor = [UIColor clearColor];
    self.contentMode = UIViewContentModeRedraw;
    [view addSubview:backView];
    [backView addSubview:self];
    
    f.size = [self contentSizeForViewInPopoverView];
   
    if ( ! CGPointEqualToPoint( point, CGPointZero ) )
    {
        f.origin.y = point.y - f.size.height;
        if (f.origin.x < 1.0 )
            f.origin.x = (view.frame.size.width - f.size.width)/2.0;
        self.frame = f;
        self.xArrow = point.x - self.frame.origin.x;
    }
    else
    {
        if (f.origin.x < 1.0 )
            f.origin.x = (view.frame.size.width - f.size.width)/2.0;
        f.origin.y = (self.yOffset > 1 ) ? self.yOffset : (view.bounds.size.height - f.size.height)/2.0; // 30
        self.xArrow = -1;
    }
    self.frame = f;

    if ( animated )
    {
        self.alpha = 0.0;
        [UIView animateWithDuration:0.3f
                         animations:^{
                             self.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                         }
         ];
    }
}

- (void) dismissAnimated:(BOOL)animated
{
    [self killAutodismissTimer];
    [UIView animateWithDuration:animated ? 0.3f : 0.0
             animations:^{
                 self.alpha = 0.0;
             }
             completion:^(BOOL finished) {
                 self.alpha = 1.0;
                 self.hidden = YES;
                 if ( [self.superview isKindOfClass:[UITouchView class]] )
                 {
                     [self.superview removeFromSuperview];
#if !__has_feature(objc_arc)
                     [self.superview release];
#endif //
                 }
                 [self removeFromSuperview];
#if !__has_feature(objc_arc)
                 [self release];
#endif //
             }
     ];
}

- (CGSize) contentSizeForViewInPopoverView
{
    // default size, override this function in the subclass to set the required size
    return self.frame.size;
}



@end
