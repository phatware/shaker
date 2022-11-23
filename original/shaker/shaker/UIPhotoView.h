//
//  UIPhotoView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/21/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"

#define TAKE_PHOTO_NOTIFICATION     @"TAKE_PHOTO_NOTIFICATION"

@interface UIPhotoView : UICustomPopupView

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image;

@end
