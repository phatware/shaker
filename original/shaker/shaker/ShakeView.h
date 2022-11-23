//
//  ShakeView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/18/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShakeViewPritocol <NSObject>

- (void) didShake:(UIView *)sender;
- (void) startShake:(UIView *)sender;

@end


@interface ShakeView : UIView

@property (nonatomic, weak) id <ShakeViewPritocol> delegate;

@property (nonatomic, assign) BOOL ignoreEvents;

@end
