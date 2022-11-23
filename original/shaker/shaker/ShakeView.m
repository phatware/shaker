//
//  ShakeView.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/18/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "ShakeView.h"
#import "SoundManager.h"

@interface ShakeView()
{
}

@property (nonatomic, strong ) Sound * sound_shake;

@end

@implementation ShakeView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake && (!self.ignoreEvents) )
    {
        if ( nil == self.sound_shake )
            self.sound_shake = [Sound soundNamed:@"shake.aifc"];
        [[SoundManager sharedManager] stopMusic:NO];
        [[SoundManager sharedManager] playSound:self.sound_shake looping:YES fadeIn:NO];
        if ( self.delegate && [self.delegate respondsToSelector:@selector(startShake:)] )
        {
            [self.delegate startShake:self];
        }
    }
    
    if ([super respondsToSelector:@selector(motionBegan:withEvent:)])
    {
        [super motionBegan:motion withEvent:event];
    }
}

- (void) motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [[SoundManager sharedManager] stopAllSounds:NO];
    if ([super respondsToSelector:@selector(motionCancelled:withEvent:)])
    {
        [super motionCancelled:motion withEvent:event];
    }
}

- (void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [[SoundManager sharedManager] stopAllSounds:NO];
    if ( event.subtype == UIEventSubtypeMotionShake  && (!self.ignoreEvents) )
    {
        if ( self.delegate && [self.delegate respondsToSelector:@selector(didShake:)] )
        {
            [self.delegate didShake:self];
        }
    }
    
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)])
    {
        [super motionEnded:motion withEvent:event];
    }
}

@end
