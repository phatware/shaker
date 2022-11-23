//
//  UIColor+CustomColor.m
//  WritePad
//
//  Created by Stanislav Miasnikov on 1/2/16.
//
//

#import "UIColor+CustomColor.h"
#import "utils.h"

@implementation UIColor (CustomColor)

- (NSString *) hexStringFromColor;
{
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue: &b alpha: &a];
    int rr, gg, bb, aa;
    rr = (int)(255.0 * r);
    gg = (int)(255.0 * g);
    bb = (int)(255.0 * b);
    aa = (int)(255.0 * a);

    return [NSString stringWithFormat:@"rgb(%d, %d, %d)",rr,gg,bb ];
}

#ifdef RGB_COLOR_SUPPORT

#import "RecognizerApi.h"

- (UInt32) uiColorToColorRef
{
    CGColorRef	 colorref = [self CGColor];
    const CGFloat * colorComponents = CGColorGetComponents(colorref);
    UInt32	 coloref = RGBA( CCTB(colorComponents[0]), CCTB(colorComponents[1]), CCTB(colorComponents[2]), CCTB(colorComponents[3]) );
    return coloref;
}

- (CGFloat) uiColorAlpha
{
    CGColorRef	 colorref = [self CGColor];
    const CGFloat * colorComponents = CGColorGetComponents(colorref);
    return colorComponents[3];
}

+ (UIColor *) uiColorRefToColor:(UInt32)coloref
{
    if ( coloref == 0 )
    {
        UIColor * color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        return color;
    }
    else
    {
        UIColor * color = [UIColor colorWithRed:GetRValue(coloref) green:GetGValue(coloref) blue:GetBValue(coloref) alpha:GetAValue(coloref)];
        return color;
    }
}

#endif // RGB_COLOR_SUPPORT

#pragma mark -- Tint Color support

#define kTotalTintColors	      10

static NSInteger tintColotIndex = 0;
static bool __invert = false;

+ (NSInteger) getCurrentTintColorIndex
{
    return tintColotIndex;
}

+ (NSInteger) numOfTintColors
{
    return kTotalTintColors;
}

+ (void) setCurrentTintColor:(NSInteger)index
{
    if ( index >= 0 && index < kTotalTintColors )
    {
        tintColotIndex = index;
        [[NSUserDefaults standardUserDefaults] setInteger:tintColotIndex forKey:kWritePadTintColor];
        [[NSNotificationCenter defaultCenter] postNotificationName:WRITEPAD_THEMECOLORCHANGED_NOTIFICATION object:[UIColor getCurrentTintColor]];
    }
}

+ (void) initTintColor
{
    __invert = [[NSUserDefaults standardUserDefaults] boolForKey:kWritePadSettings_InvertColors];
    tintColotIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kWritePadTintColor];
}

+ (UIColor *) getTintColorFromIndex:(NSInteger)index
{
    switch( index )
    {
        case 1 :    // blue
            return [UIColor colorWithRed:(0x14/255.0) green:(0x7e/255.0) blue:(0xfb/255.0) alpha:1.0];  // keep
            // return [UIColor colorWithRed:(174.0/255.0) green:(64.0/255.0) blue:(55.0/255.0) alpha:1.0];
        case 2 :    // teal
            return [UIColor colorWithRed:(0x40/255.0) green:(0xae/255.0) blue:(0xba/255.0) alpha:1.0];
        case 3 :    // green
            return [UIColor colorWithRed:(0x30/255.0) green:(0x80/255.0) blue:(0x14/255.0) alpha:1.0];  // keep
            // return [UIColor colorWithRed:(22.0/255.0) green:(132.0/255.0) blue:(20.0/255.0) alpha:1.0];
        case 4 :    // yellow
            return [UIColor colorWithRed:(0xff/255.0) green:(0xb4/255.0) blue:(0x04/255.0) alpha:1.0];  // keep
        case 5 :    // orange
            return [UIColor orangeColor];
        case 6 :    // pink
            return [UIColor colorWithRed:(0xe0/255.0) green:(0x42/255.0) blue:(0x7f/255.0) alpha:1.0];  // keep
        case 7 :    // red
            return [UIColor colorWithRed:(0xcc/255.0) green:(0x11/255.0) blue:(0x00/255.0) alpha:1.0];
        case 8 :    // gray
            return [UIColor colorWithRed:(0x6c/255.0) green:(0x7b/255.0) blue:(0x8b/255.0) alpha:1.0];  // keep
        case 9 :    // black
            return [UIColor colorWithRed:(0x15/255.0) green:(0x15/255.0) blue:(0x15/255.0) alpha:1.0];
    }
    // purple (default)  #5271ff
    return [UIColor colorWithRed:(0x52/255.0) green:(0x71/255.0) blue:(0xff/255.0) alpha:1.0];
    // return [UIColor colorWithRed:(88.0/255.0) green:(161.0/255.0) blue:(73.0/255.0) alpha:1.0];
}

+ (UIColor *) getCurrentTintColor
{
    return [UIColor colorNamed:@"PenquillsColor"];
}

+ (UIColor *) tintColor
{
    // TODO: iOS13
    return [UIColor getCurrentTintColor];
}

+ (UIColor *) darkColor
{
    return [UIColor colorNamed:@"DarkColor"];
}

+ (UIColor *) lightColor
{
    return [UIColor colorNamed:@"LightColor"];
}

+ (UIColor *) defaultInkColor
{
    return [UIColor colorNamed:@"InkColor"];
}

+ (UIColor *)  defaultTintColor
{
    return [UIColor getTintColorFromIndex:0];
}

+ (BOOL) isInverted
{
    return __invert;
}

+ (void) invertColors:(BOOL)invert
{
    __invert = invert;
    [[NSUserDefaults standardUserDefaults] setBool:__invert forKey:kWritePadSettings_InvertColors];
    [[NSNotificationCenter defaultCenter] postNotificationName:WRITEPAD_THEMECOLORCHANGED_NOTIFICATION object:[UIColor getCurrentTintColor]];
}

+ (UIColor *) barTintColor
{
    return [UIColor lightColor];
}

+ (UIColor *) navTintColor
{
    return [self getCurrentTintColor];
}

+ (UIColor *) getBackgroundColor
{
    return [UIColor lightColor];
}

@end
