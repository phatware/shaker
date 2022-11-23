//
//  UIRatingView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/20/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"


@class UIRatingView;

@protocol UIRatingViewProtocol <NSObject>

- (BOOL) ratingView:(UIRatingView *)view rating:(int)rating;

@end

@interface UIRatingView : UICustomPopupView

@property (nonatomic, assign) int rating;
@property (nonatomic, assign) BOOL userRating;
@property (nonatomic, assign) id<UIRatingViewProtocol> delegate;

@end
