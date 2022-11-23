//
//  UIShoppingView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"

@protocol UIShoppingViewDelegate <NSObject>

- (void) onSendShoppingList:(UIButton *)sender using:(NSInteger)service;

@end

@interface UIShoppingView : UICustomPopupView

@property (nonatomic, weak) id<UIShoppingViewDelegate> delegate;

@end
