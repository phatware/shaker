//
//  utils.h
//  WritePadPro
//
//  Created by Stanislav Miasnikov on 1/13/09.
//  Copyright 2009 PhatWare Corp.. All rights reserved.
//

#pragma once

#import <UIKit/UIKit.h>
#import "UIAlertController+Progress.h"
#import "UIColor+CustomColor.h"

#define CFSafeRelease( x )  if (NULL!=x) {CFRelease(x); x = NULL;}
#define NSStringReplace(str,find,replace) [str replaceOccurrencesOfString:find withString:replace options:NSLiteralSearch range:NSMakeRange(0,[str length])]

enum
{
    UIDeviceResolution_Unknown          = 0,
    UIDeviceResolution_iPhoneStandard   = 1,    // iPhone 1,3,3GS Standard Display  (320x480px)
    UIDeviceResolution_iPhoneRetina35   = 2,    // iPhone 4,4S Retina Display 3.5"  (640x960px)
    UIDeviceResolution_iPhoneRetina4    = 3,    // iPhone 5 Retina Display 4"       (640x1136px)
    UIDeviceResolution_iPadStandard     = 4,    // iPad 1,2 Standard Display        (1024x768px)
    UIDeviceResolution_iPadRetina       = 5     // iPad 3 Retina Display            (2048x1536px)
};

typedef NSUInteger UIDeviceResolution;

#define NSLocalizedTableTitle( str )    [NSString stringWithFormat:@"   %@", NSLocalizedString( str, @"" )]
#define LOC( str )                      NSLocalizedString( str, @"" )
#define LOCT( str )                     NSLocalizedTableTitle( str )

/////////////////////////////////////////////////////////////////////////////

@interface utils : NSObject
{

}

+ (BOOL) fileName:(NSString *)name isKindOf:(NSString *)ext;
+ (NSString *) contentTypeForName:(NSString *)filename;
+ (NSString *) getShortFileName:(NSString *)filename;
+ (NSString *)uuid;
+ (BOOL) validateUrl:(NSString *)candidate;
+ (NSString *) getFileType:(NSString *)filename;

+ (NSString *)appNameAndVersionNumberDisplayString;
+ (NSString *) shortFileName:(NSString *)fileName;
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;

#ifndef _WATCH_KIT

+ (NSInteger) getMajorOSVersion;
+ (NSString *) getDeviceInfo;
+ (UIDeviceResolution)resolution;
+ (NSString *) deviceNameFromService:(NSNetService *)service;
+ (NSString *) imagesWithBase64:(UIImage *)image;
+ (void) networkConnectionWarning;
+ (void) showUserMessage:(NSString *)message withTitle:(NSString *)title;
+ (NSArray *) nameFromDeviceName:(NSString *)deviceName;
+ (BOOL) isRetina;

#endif // _WATCH_KIT

+ (NSString *) generateTempFileName:(NSString *)ext;
+ (CGSize)calcMaxImageSize:(CGSize)size maxWidth:(CGFloat)maxPageSize;
+ (CGFloat) distanceFrom:(CGPoint)from toPoint:(CGPoint)to;

+ (NSUserDefaults *) shakerGroupUserDefaults;

+ (void) setCurrentTintColor:(NSInteger)index;
+ (UIColor *) getCurrentTintColor;
+ (NSInteger) getCurrentTintColorIndex;
+ (NSInteger) numOfTintColors;
+ (UIColor *) getTintColorFromIndex:(NSInteger)index;

+ (UIImage *) colorImageWithName:(NSString *)name color:(UIColor *)col mode:(CGBlendMode)m;
+ (UIImage *) colorImageWithImage:(UIImage *)name color:(UIColor *)col mode:(CGBlendMode)m;
+ (UIImage *) imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize alpha:(CGFloat)alpha;

@end

#if (TARGET_OS_IPHONE)
@interface NSObject (classNameAPI)
- (NSString *)className;
+ (NSString *)className;
@end
#endif

CG_INLINE CGSize
CGSizeScale( CGSize size, CGFloat scale)
{
    CGSize result;
    result.width = size.width/scale;
    result.height = size.height/scale;
    return result;
}

#define kShakerAllRecipesVisible        @"ShakerAllRecipesVisible"
#define kShakerHideDisclaimer           @"ShakerHideDisclaimer"
#define kShakerShowAllIngredients       @"ShakerShowAllIngredients"
#define kShakerPlayMusic                @"ShakerPlayMusic"
#define kShakerMusicVolume              @"ShakerMusicVolume"
#define kShakerIngredientsSortOrder     @"ShakerIngredientsSortOrder"
#define kShakerSearchRecipesScope       @"ShakerSearchRecipesScope"



