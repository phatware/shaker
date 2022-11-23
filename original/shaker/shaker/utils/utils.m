//
//  utils.m
//  WritePadPro
//
//  Created by Stanislav Miasnikov on 1/13/09.
//  Copyright 2009 PhatWare Corp.. All rights reserved.
//

#import "utils.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#ifndef _WATCH_KIT
#import "GTLBase64.h"
#endif


extern NSString *	g_appName;
extern NSData *		g_deviceToken;

#define radians( degrees ) ( (degrees) * M_PI / 180.0 ) 

@implementation utils

+ (CGFloat) distanceFrom:(CGPoint)from toPoint:(CGPoint)to
{
	CGFloat cx = from.x - to.x;
	CGFloat cy = from.y - to.y;	
	return sqrt( cx * cx + cy * cy );
}

+ (NSString *) generateTempFileName:(NSString *)ext
{
    // NSString * tempDir = NSTemporaryDirectory();
    
    static unsigned int counter = 0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tempDir = [paths objectAtIndex:0];
    NSString *name = [NSString stringWithFormat:@"tempfile_%u_%u%@",
                      ++counter, (unsigned int) arc4random(), ext];
    NSString *result = [tempDir stringByAppendingPathComponent:name];
    
    return result;
}

+ (NSUserDefaults *) shakerGroupUserDefaults
{
    NSUserDefaults*	defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.phunkware.shaker"];
#if __has_feature(objc_arc)
    return defaults;
#else
    return [defaults autorelease];
#endif
}


+ (CGSize)calcMaxImageSize:(CGSize)size maxWidth:(CGFloat)maxPageSize
{
    CGFloat maxImageSize = MAX( size.width, size.height );
    CGSize  fImage = size;
    if ( maxImageSize >= maxPageSize )
    {
        // resize the image if it is too large
        CGFloat     ratio = 1.0;
        if ( size.width > size.height )
            ratio = maxPageSize/size.width;
        else
            ratio = maxPageSize/size.height;
        
        fImage.height = size.height * ratio;
        fImage.width = size.width * ratio;
    }
    return fImage;
}

+ (NSString *)appNameAndVersionNumberDisplayString
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    return [NSString stringWithFormat:@"%@ %@", appDisplayName, minorVersion];
}


+ (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString * result = [NSString stringWithString:(__bridge NSString *)uuidStringRef];
    CFRelease(uuidStringRef);
    return result;
}


+ (BOOL) validateUrl:(NSString *)candidate
{
    NSString *urlRegEx = @"(https?|ftp|gopher|telnet|file|notes|ms-help):((//)|(\\\\))+((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

#ifndef _WATCH_KIT

+ (NSString *) getDeviceInfo
{
    NSMutableString * results = [[NSMutableString alloc] init];
    
    // [results appendFormat:@"Identifier:\n %@\n", [[UIDevice currentDevice] uniqueIdentifier]];
    [results appendFormat:@"Device Model: %@\n", [[UIDevice currentDevice] model]];
    [results appendFormat:@"Localized Model: %@\n", [[UIDevice currentDevice] localizedModel]];
    [results appendFormat:@"Device Name: %@\n", [[UIDevice currentDevice] name]];
    [results appendFormat:@"System Name: %@\n", [[UIDevice currentDevice] systemName]];
    [results appendFormat:@"System Version: %@\n", [[UIDevice currentDevice] systemVersion]];
    [results appendFormat:@"Interface Idiom: %@\n", ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"iPhone" : @"iPad"];
    
    NSLog( @"%@", results );
#if !__has_feature(objc_arc)
    return (NSString *)[results autorelease];
#else
    return (NSString *)results;
#endif
}

+ (UIDeviceResolution)resolution
{
    UIDeviceResolution resolution = UIDeviceResolution_Unknown;
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGFloat scale = ([mainScreen respondsToSelector:@selector(scale)] ? mainScreen.scale : 1.0f);
    CGFloat pixelHeight = (CGRectGetHeight(mainScreen.bounds) * scale);
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (scale == 2.0f)
        {
            if (pixelHeight == 960.0f)
                resolution = UIDeviceResolution_iPhoneRetina35;
            else if (pixelHeight == 1136.0f)
                resolution = UIDeviceResolution_iPhoneRetina4;
            
        }
        else if (scale == 1.0f && pixelHeight == 480.0f)
            resolution = UIDeviceResolution_iPhoneStandard;
    }
    else
    {
        if (scale == 2.0f && pixelHeight == 2048.0f)
        {
            resolution = UIDeviceResolution_iPadRetina;
            
        }
        else if (scale == 1.0f && pixelHeight == 1024.0f)
        {
            resolution = UIDeviceResolution_iPadStandard;
        }
    }
    
    return resolution;
}

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))

+ (BOOL) isRetina
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    return [mainScreen respondsToSelector:@selector(displayLinkWithTarget:selector:)] && (mainScreen.scale == 2.0);
}


+ (NSString *) imagesWithBase64:(UIImage *)image
{
    if ( image == nil )
        return nil;
    NSData * imageData = UIImageJPEGRepresentation( image, 0.8 );
    NSString * base64 = GTLEncodeBase64( imageData );
    if ( base64.length > 0 )
    {
        // Add uniq id to img tag
        NSString * src = @"data:image/png;base64,";
        src = [src stringByAppendingString:base64];
        return src;
    }
    return nil;
    
}

+ (void) networkConnectionWarning
{
    [UIAlertController networkConnectionWarningWithSettings];
}

+ (void) showUserMessage:(NSString *)message withTitle:(NSString *)title
{
    [UIAlertController showMessage:message withTitle:title];
}

+ (NSString *) deviceNameFromService:(NSNetService *)service
{
	// set remote name
	// see if the service name contain the device name
	NSString *	deviceName = @"iPhone";
	NSString *	name = [service name];
	NSRange rFrom = [name rangeOfString:@"("];
	NSRange rTo = [name rangeOfString:@")"];
	if ( rFrom.location != NSNotFound && rTo.location != NSNotFound && rTo.location-1 > rFrom.location+1 )
	{
		// use device name
		rFrom.location++;
		rFrom.length = rTo.location - rFrom.location;
		deviceName = [name substringWithRange:rFrom];
	}
	else
	{
		// use host name
		deviceName = [service hostName];
		NSRange		r = [deviceName rangeOfString:@"."];
		if ( r.location != NSNotFound )
			deviceName = [[service hostName] substringToIndex:r.location];
	}
	return deviceName;
}

+ (NSInteger) getMajorOSVersion
{
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ( nil == versionCompatibility )
        return 0;
    return [[versionCompatibility objectAtIndex:0] intValue];
}


#endif // _WATCH_KIT

+ (NSString *) getShortFileName:(NSString *)filename
{
	NSInteger	index = [filename rangeOfString:@"/" options:NSBackwardsSearch].location;
	if ( index == NSNotFound )
		index = 0;
	else
		index++;
	NSString * sTitle = [filename substringFromIndex:index];
	NSRange r = [sTitle rangeOfString:@"." options:NSBackwardsSearch];
	if ( r.location != NSNotFound && r.location > 0 )
		sTitle = [sTitle substringToIndex:r.location];
#if !__has_feature(objc_arc)
	return [[[NSString alloc] initWithString:sTitle] autorelease];
#else
    return sTitle;
#endif
}

+ (NSString *) contentTypeForName:(NSString *)filename
{
    NSInteger len = [filename length];
    if ( len > 5 )
    {
        if ( [[filename substringFromIndex:(len-4)] caseInsensitiveCompare:@".htm"] == NSOrderedSame )
            return @"text/html";
        if ( [[filename substringFromIndex:(len-5)] caseInsensitiveCompare:@".html"] == NSOrderedSame )
            return @"text/html";
        if ( [[filename substringFromIndex:(len-4)] caseInsensitiveCompare:@".rtf"] == NSOrderedSame )
            return @"text/rtf";
        if ( [[filename substringFromIndex:(len-5)] caseInsensitiveCompare:@".jpeg"] == NSOrderedSame )
            return @"image/jpeg";
        if ( [[filename substringFromIndex:(len-4)] caseInsensitiveCompare:@".jpg"] == NSOrderedSame )
            return @"image/jpeg";
        if ( [[filename substringFromIndex:(len-4)] caseInsensitiveCompare:@".png"] == NSOrderedSame )
            return @"image/png";
    }
    return @"binary/octet-stream";
}

+ (NSArray *) nameFromDeviceName:(NSString *)deviceName
{
    NSError * error;
    static NSString * expression = (@"^(?:iPhone|phone|iPad|iPod)\\s+(?:de\\s+)?|"
                                    "(\\S+?)(?:['’]?s)?(?:\\s+(?:iPhone|phone|iPad|iPod))?$|"
                                    "(\\S+?)(?:['’]?的)?(?:\\s*(?:iPhone|phone|iPad|iPod))?$|"
                                    "(\\S+)\\s+");
    static NSRange RangeNotFound = (NSRange){.location=NSNotFound, .length=0};
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                            options:(NSRegularExpressionCaseInsensitive)
                                                                              error:&error];
    NSMutableArray * name = [NSMutableArray new];
    for (NSTextCheckingResult * result in [regex matchesInString:deviceName
                                                         options:0
                                                           range:NSMakeRange(0, deviceName.length)])
    {
        for (int i = 1; i < result.numberOfRanges; i++)
        {
            if (! NSEqualRanges([result rangeAtIndex:i], RangeNotFound))
            {
                [name addObject:[deviceName substringWithRange:[result rangeAtIndex:i]].capitalizedString];
            }
        }
    }
    return name;
}

+ (BOOL) fileName:(NSString *)name isKindOf:(NSString *)ext
{
    NSUInteger len1 = [name length];
    NSUInteger len2 = [ext length];
    if ( len1 > len2 && [[name substringFromIndex:(len1-len2)] caseInsensitiveCompare:ext] == NSOrderedSame )
        return YES;
    return NO;
}

#pragma mark global push notification functions

+ (NSString *) getFileType:(NSString *)filename
{
    NSString * type = nil;
    
    NSInteger  index = [filename rangeOfString:@"." options:(NSCaseInsensitiveSearch | NSBackwardsSearch)].location;
    if ( index != NSNotFound && index < [filename length] - 1 )
        type = [filename substringFromIndex:index];
    return type;
}

+ (NSString *)shortFileName:(NSString *)strFileName
{
	NSString * name;
	if ( [strFileName length] < 1 )
	{
		name = @"<filename>";
	}
	else
	{
		NSInteger  index = [strFileName rangeOfString:@"/" options:(NSCaseInsensitiveSearch | NSBackwardsSearch)].location;
		if ( index != NSNotFound && index < [strFileName length] - 1 )
			name = [strFileName substringFromIndex:(index+1)];
		else 
			name = strFileName;
	}
	return name;
}

#pragma mark -- Tint Color support

#define kTotalTintColors	6
static NSInteger tintColotIndex = 0;

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
	}
}

+ (UIColor *) getTintColorFromIndex:(NSInteger)index
{
	switch( index )
	{
		case 1 :
			return [UIColor colorWithRed:(174.0/255.0) green:(64.0/255.0) blue:(55.0/255.0) alpha:1.0];
		case 4 :
			return [UIColor colorWithRed:(45.0/255.0) green:(125.0/255.0) blue:(187.0/255.0) alpha:1.0];
		case 3 :
			return [UIColor orangeColor];
		case 2 :
			return [UIColor brownColor];
		case 5 :
			return [UIColor colorWithRed:(0x15/255.0) green:(0x70/255.0) blue:(0xd5/255.0) alpha:1.0];
	}
	return [UIColor colorWithRed:(22.0/255.0) green:(124.0/255.0) blue:(20.0/255.0) alpha:1.0];
    // [UIColor colorWithRed:(88.0/255.0) green:(161.0/255.0) blue:(73.0/255.0) alpha:1.0];
}

+ (UIColor *) getCurrentTintColor
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    if ( [appDisplayName isEqualToString:@"Penquills"] )
        return [UIColor orangeColor];
    
	return [utils getTintColorFromIndex:tintColotIndex];
}

#pragma mark -- Image scaling

+ (UIImage *) colorImageWithName:(NSString *)name color:(UIColor *)col mode:(CGBlendMode)m
{
    UIImage * img = [UIImage imageNamed:name];
    if ( img == nil )
        return nil;

    return [utils colorImageWithImage:img color:col mode:m];
}

+ (UIImage *) colorImageWithImage:(UIImage *)img color:(UIColor *)col mode:(CGBlendMode)m
{
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContextWithOptions( img.size, NO, img.scale );
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ( context == nil )
        return nil;
    
    // set the fill color
    [col setFill];
    
    CGContextSetShouldAntialias(context, YES );
    CGContextSetFlatness(context, 0.1);
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, m);
    // CGContextSetAlpha(context, 0.9 );
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}

#if 0

enum CGBlendMode {
    /* Available in Mac OS X 10.4 & later. */
    kCGBlendModeNormal,
    kCGBlendModeMultiply,
    kCGBlendModeScreen,
    kCGBlendModeOverlay,
    kCGBlendModeDarken,
    kCGBlendModeLighten,
    kCGBlendModeColorDodge,
    kCGBlendModeColorBurn,
    kCGBlendModeSoftLight,
    kCGBlendModeHardLight,
    kCGBlendModeDifference,
    kCGBlendModeExclusion,
    kCGBlendModeHue,
    kCGBlendModeSaturation,
    kCGBlendModeColor,
    kCGBlendModeLuminosity,
    
    /* Available in Mac OS X 10.5 & later. R, S, and D are, respectively,
     premultiplied result, source, and destination colors with alpha; Ra,
     Sa, and Da are the alpha components of these colors.
     
     The Porter-Duff "source over" mode is called `kCGBlendModeNormal':
     R = S + D*(1 - Sa)
     
     Note that the Porter-Duff "XOR" mode is only titularly related to the
     classical bitmap XOR operation (which is unsupported by
     CoreGraphics). */
    
    kCGBlendModeClear,			/* R = 0 */
    kCGBlendModeCopy,			/* R = S */
    kCGBlendModeSourceIn,		/* R = S*Da */
    kCGBlendModeSourceOut,		/* R = S*(1 - Da) */
    kCGBlendModeSourceAtop,		/* R = S*Da + D*(1 - Sa) */
    kCGBlendModeDestinationOver,	/* R = S*(1 - Da) + D */
    kCGBlendModeDestinationIn,		/* R = D*Sa */
    kCGBlendModeDestinationOut,		/* R = D*(1 - Sa) */
    kCGBlendModeDestinationAtop,	/* R = S*(1 - Da) + D*Sa */
    kCGBlendModeXOR,			/* R = S*(1 - Da) + D*(1 - Sa) */
    kCGBlendModePlusDarker,		/* R = MAX(0, (1 - D) + (1 - S)) */
    kCGBlendModePlusLighter		/* R = MIN(1, S + D) */
};

#endif

+ (UIImage *) imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize alpha:(CGFloat)alpha
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, newSize.width, newSize.height);
    if ( alpha < 1.0 )
    {
        [[UIColor whiteColor] setFill];
        CGContextFillRect( UIGraphicsGetCurrentContext(), rect);
    }
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height) blendMode:(kCGBlendModeNormal) alpha:alpha];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


// image scaler...
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize
{  
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
	
    if ( CGSizeEqualToSize(imageSize, targetSize) == NO ) 
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor) 
		{
            scaleFactor = widthFactor; // scale to fit height
        }
        else 
		{
            scaleFactor = heightFactor; // scale to fit width
        }
		
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
        if (widthFactor > heightFactor)
		{
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else if (widthFactor < heightFactor)
		{
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }     
	
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
	
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipLast;
    }
	
    CGContextRef bitmap;
	
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) 
	{
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
    } 
	else 
	{
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
    }   
	
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft)
	{
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
		
        CGContextRotateCTM (bitmap, radians(90));
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
		
    } 
	else if (sourceImage.imageOrientation == UIImageOrientationRight)
	{
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
		
        CGContextRotateCTM (bitmap, radians(-90));
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
		
    } else if (sourceImage.imageOrientation == UIImageOrientationUp)
	{
        // NOTHING
    } 
	else if (sourceImage.imageOrientation == UIImageOrientationDown) 
	{
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, radians(-180.));
    }
	
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
	
    CGContextRelease(bitmap);
    CGImageRelease(ref);
	
    return newImage; 
}


@end

#if (TARGET_OS_IPHONE)

#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (classNameAPI)

- (NSString *)className
{
	return [NSString stringWithUTF8String:class_getName([self class])];
}

+ (NSString *)className
{
	return [NSString stringWithUTF8String:class_getName(self)];
}

@end

#endif
