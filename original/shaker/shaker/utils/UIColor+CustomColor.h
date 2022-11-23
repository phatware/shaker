//
//  UIColor+CustomColor.h
//  WritePad
//
//  Created by Stanislav Miasnikov on 1/2/16.
//
//

#import <UIKit/UIKit.h>

#define kWritePadTintColor					        @"WritePadTintColor"
#define kWritePadSettings_InvertColors              @"WritePadSettings_InvertColors"

#define WRITEPAD_THEMECOLORCHANGED_NOTIFICATION		@"WRITEPAD_THEMECOLORCHANGED_NOTIFICATION"

#define UITableViewSetSepColor                      self.tableView.separatorColor = [[UIColor getCurrentTintColor] colorWithAlphaComponent:0.25]

#define SET_BACK_COLOR(bc)  if ( [utils systemMajorVersion] < 13 ) { bc = [UIColor getBackgroundColor]; }

#define SET_BLACK_COLOR(bc) if ( [utils systemMajorVersion] < 13 ) { bc = [UIColor blackColor]; }
#define SET_WHITE_COLOR(bc) if ( [utils systemMajorVersion] < 13 ) { bc = [UIColor whiteColor]; }
#define SET_CLEAR_COLOR(bc) if ( [utils systemMajorVersion] < 13 ) { bc = [UIColor clearColor]; }

#define SET_TINT_COLOR(ctrl)                        \
if ( [utils systemMajorVersion] < 13 ) {            \
    ctrl.tintColor = [UIColor getCurrentTintColor]; \
}

#define SET_SWITCH_TINT_COLOR(sw)                   \
if ( [utils systemMajorVersion] < 13 ) {            \
    sw.tintColor = [UIColor getCurrentTintColor];   \
    sw.onTintColor = [UIColor getCurrentTintColor]; \
}


@interface UIColor (CustomColor)

+ (void) setCurrentTintColor:(NSInteger)index;
+ (UIColor *) getCurrentTintColor;
+ (UIColor *) defaultTintColor;
+ (NSInteger) getCurrentTintColorIndex;
+ (NSInteger) numOfTintColors;
+ (UIColor *) getTintColorFromIndex:(NSInteger)index;
+ (void) initTintColor;
+ (UIColor *) barTintColor;
+ (UIColor *) navTintColor;
+ (void) invertColors:(BOOL)invert;
+ (UIColor *) getBackgroundColor;
+ (BOOL) isInverted;
- (NSString *) hexStringFromColor;
+ (UIColor *) darkColor;
+ (UIColor *) lightColor;
+ (UIColor *) defaultInkColor;

#ifdef RGB_COLOR_SUPPORT

- (UInt32) uiColorToColorRef;
- (CGFloat) uiColorAlpha;

+ (UIColor *) uiColorRefToColor:(UInt32)rgb;

#endif // RGB_COLOR_SUPPORT


@end
