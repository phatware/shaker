//
//  RateApplication.h
//  Tempest
//
//  Created by Stanislav Miasnikov on 5/24/15.
//  Copyright (c) 2015 PhatWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Availability.h>

@interface RateApplication : NSObject

@property (nonatomic, assign) NSInteger usesBrforePrompt;
@property (nonatomic, assign) NSInteger daysBeforePrompt;
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;

+ (RateApplication *) sharedInstance;

- (BOOL) canRate:(BOOL)prompt;
- (void) promptToRate:(id)object;

@end
