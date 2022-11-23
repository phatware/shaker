//
//  UICustomPopupView.h
//  Shaker
//
//  Created by Stanislav Miasnikov on 1/27/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UICustomPopupView : UIView
{
    
}

@property (nonatomic, assign) BOOL bottomArrow;
@property (nonatomic, assign) CGFloat xArrow;
@property (nonatomic, assign) CGFloat yOffset;
@property (nonatomic, retain) UIColor * backColor;
@property (nonatomic, retain) UIColor * outlineColor;
@property (nonatomic, retain) UIColor * titleBackColor;
@property (nonatomic, retain) UIColor * titleColor;
@property (nonatomic, copy ) NSString * title;


- (void) presentInView:(UIView * )view fromPoint:(CGPoint)point animated:(BOOL)animated;
- (void) showInView:(UIView * )view fromPoint:(CGPoint)point animated:(BOOL)animated autodismiss:(NSTimeInterval)timeinterval;
- (void) dismissAnimated:(BOOL)animated;
- (CGSize) contentSizeForViewInPopoverView;
- (CGRect) clientRect;
- (void) adjustPositionToPoint:(CGPoint)point;
- (void) popupInView:(UIView *)view fromPoint:(CGPoint)point;

@end
