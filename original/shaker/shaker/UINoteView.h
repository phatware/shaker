//
//  UINoteView.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/22/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UICustomPopupView.h"

@protocol UINoteViewDelegate <NSObject>

- (void) onSetNoteText:(NSString *)text;

@end

@interface UINoteView : UICustomPopupView <UITextViewDelegate>

@property (nonatomic, weak) id<UINoteViewDelegate> delegate;
@property (nonatomic, strong) UITextView * textView;

- (id)initWithFrame:(CGRect)frame initialText:(NSString *)text;

@end
