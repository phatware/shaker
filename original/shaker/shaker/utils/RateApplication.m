//
//  RateApplication.m
//  Tempest
//
//  Created by Stanislav Miasnikov on 5/24/15.
//  Copyright (c) 2015 PhatWare. All rights reserved.
//

#import "RateApplication.h"
#import "utils.h"
#import "UIAlertController+Progress.h"

extern BOOL gDisablePrompt;

@interface RateApplication()
{
    BOOL    _background_check;
}

@property (nonatomic, retain) NSString * appStoreCountry;
@property (nonatomic, retain) NSString * applicationVersion;
@property (nonatomic, retain) NSString * applicationName;
@property (nonatomic, retain) NSString * applicationBundleID;

@property (nonatomic, assign) NSInteger applicationStoreID;
@property (nonatomic, assign) NSInteger applicationStoreGenreID;

@end

#define kRateApplicationUsesCount       @"RateApplicationUsesCount"
#define kRateApplicationInstallDate     @"RateApplicationInstallDate"
#define kRateApplicationDontPrompt      @"RateApplicationDontPrompt"
#define kRateApplicationRatedVersion    @"RateApplicationRatedVersion"
#define kRateApplicationStoreID         @"RateApplicationStoreID"

static NSString *const rateAppStoreURLFormat = @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8&id=%@";

// static NSString *const rateAppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
static NSString *const rateAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";


#define REQUEST_TIMEOUT 60.0
#define DAY_SECONDS     3600.0 * 24.0

@implementation RateApplication


static RateApplication * gRater = nil;

+ (RateApplication *) sharedInstance
{
    @synchronized(self)
    {
        if ( nil == gRater )
        {
            gRater = [[RateApplication alloc] init];
        }
    }
    return gRater;
}

- (id)init
{
    if ( (self = [super init]) != nil )
    {
        //register for iphone application events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        //get country
        self.appStoreCountry = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if ( self.appStoreCountry == nil )
            self.appStoreCountry = [[NSLocale systemLocale] objectForKey:NSLocaleCountryCode];
        if ( self.appStoreCountry == nil )
            self.appStoreCountry = @"us";

        //application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([self.applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }

        //localised application name
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([self.applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }

        //bundle id
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];

        //default settings
        self.usesBrforePrompt = 10;
        self.daysBeforePrompt = 10;

        self.applicationStoreID = 0;
        self.applicationStoreGenreID = 0;
        self.onlyPromptIfLatestVersion = YES;

        _background_check = NO;
    }
    return self;
}

- (BOOL) canRate:(BOOL)prompt
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ( prompt && [defaults boolForKey:kRateApplicationDontPrompt] )
        return NO;

    if ( [self isAppRated] )
        return NO;

    NSInteger runCount = [defaults integerForKey:kRateApplicationUsesCount];
    if ( runCount < self.usesBrforePrompt )
        return NO;

    NSTimeInterval installTime = [defaults doubleForKey:kRateApplicationInstallDate];
    if ( [[NSDate date] timeIntervalSinceReferenceDate] - installTime < self.daysBeforePrompt * DAY_SECONDS )
        return NO;

    return YES;
}

- (BOOL) isAppRated
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRateApplicationRatedVersion];
}

- (void) setAppRated:(BOOL)rated
{
    [[NSUserDefaults standardUserDefaults] setBool:rated forKey:kRateApplicationRatedVersion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) applicationWillEnterForeground
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSInteger runCount = [defaults integerForKey:kRateApplicationUsesCount];
    if ( runCount < 1 )
        [defaults setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:kRateApplicationInstallDate];
    runCount++;
    [defaults setInteger:runCount forKey:kRateApplicationUsesCount];
    if ( [self canRate:YES] )
    {
        [self performSelector:@selector(checkForConnectivityInBackground:) withObject:nil afterDelay:3.0];
    }
}

- (NSString *)valueForKey:(NSString *)key inJSON:(id)id_json
{
    if ([id_json isKindOfClass:[NSString class]])
    {
        NSString * json = (NSString *)id_json;
        //use legacy parser
        NSRange keyRange = [json rangeOfString:[NSString stringWithFormat:@"\"%@\"", key]];
        if (keyRange.location != NSNotFound)
        {
            NSInteger start = keyRange.location + keyRange.length;
            NSRange valueStart = [json rangeOfString:@":" options:(NSStringCompareOptions)0 range:NSMakeRange(start, [json length] - start)];
            if (valueStart.location != NSNotFound)
            {
                start = valueStart.location + 1;
                NSRange valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(start, [json length] - start)];
                if (valueEnd.location != NSNotFound)
                {
                    NSString *value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    while ([value hasPrefix:@"\""] && ![value hasSuffix:@"\""])
                    {
                        if (valueEnd.location == NSNotFound)
                        {
                            break;
                        }
                        NSInteger newStart = valueEnd.location + 1;
                        valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(newStart, [json length] - newStart)];
                        value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    }

                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                    value = [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\f" withString:@"\f"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\b" withString:@"\f"];

                    while (YES)
                    {
                        NSRange unicode = [value rangeOfString:@"\\u"];
                        if (unicode.location == NSNotFound || unicode.location + unicode.length == 0)
                        {
                            break;
                        }

                        uint32_t c = 0;
                        NSString *hex = [value substringWithRange:NSMakeRange(unicode.location + 2, 4)];
                        NSScanner *scanner = [NSScanner scannerWithString:hex];
                        [scanner scanHexInt:&c];

                        if (c <= 0xffff)
                        {
                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C", (unichar)c]];
                        }
                        else
                        {
                            //convert character to surrogate pair
                            uint16_t x = (uint16_t)c;
                            uint16_t u = (c >> 16) & ((1 << 5) - 1);
                            uint16_t w = (uint16_t)u - 1;
                            unichar high = 0xd800 | (w << 6) | x >> 10;
                            unichar low = (uint16_t)(0xdc00 | (x & ((1 << 10) - 1)));

                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C%C", high, low]];
                        }
                    }
                    return value;
                }
            }
        }
    }
    else
    {
        return id_json[key];
    }
    return nil;
}

- (void)checkForConnectivityInBackground:(id)object
{
    if ([NSThread isMainThread])
    {
        [self performSelectorInBackground:@selector(checkForConnectivityInBackground:) withObject:object];
        return;
    }

    @autoreleasepool
    {
        //prevent concurrent checks
        if ( _background_check )
            return;
        _background_check = YES;

        //first check iTunes
        NSString *iTunesServiceURL = [NSString stringWithFormat:rateAppLookupURLFormat, self.appStoreCountry];
        if ( self.applicationStoreID > 0 ) //important that we check ivar and not getter in case it has changed
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", @(self.applicationStoreID)];
        }
        else
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
        }

        NSURLRequest *  request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL]
                                                   cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                               timeoutInterval:REQUEST_TIMEOUT];

        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
           {
               NSInteger   statusCode = ((NSHTTPURLResponse *)response).statusCode;
               if ( data && statusCode == 200 )
               {
                   //in case error is garbage...
                   error = nil;

                   NSObject * json = nil;
                   if ([NSJSONSerialization class])
                   {
                       json = [[NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error][@"results"] lastObject];
                   }
                   else
                   {
                       //convert to string
#if __has_feature(objc_arc)
                       json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#else
                       json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
#endif
                   }

                   if (!error)
                   {
                       //check bundle ID matches
                       NSString *bundleID = [self valueForKey:@"bundleId" inJSON:json];
                       if (bundleID)
                       {
                           if ([bundleID isEqualToString:self.applicationBundleID])
                           {
                               //get genre
                               if ( self.applicationStoreGenreID == 0 )
                               {
                                   self.applicationStoreGenreID = [[self valueForKey:@"primaryGenreId" inJSON:json] integerValue];
                               }

                               //get app id
                               if ( self.applicationStoreID < 1 )
                               {
                                   NSString *appStoreIDString = [self valueForKey:@"trackId" inJSON:json];
                                   [self performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:) withObject:appStoreIDString waitUntilDone:YES];
                                   NSLog(@"The App Store ID is %@", appStoreIDString);
                               }

                               //check version
                               if ( self.onlyPromptIfLatestVersion )
                               {
                                   NSString *latestVersion = [self valueForKey:@"version" inJSON:json];
                                   if ( [latestVersion compare:self.applicationVersion options:NSNumericSearch] == NSOrderedDescending )
                                   {
                                       NSLog(@"Installed application version (%@) is not the latest version on the App Store, which is %@", self.applicationVersion, latestVersion);
                                   }
                               }
                           }
                           else
                           {
                               NSLog(@"Application bundle ID (%@) does not match the bundle ID of the app found on iTunes (%@) with the specified App Store ID (%@)", self.applicationBundleID, bundleID, @(self.applicationStoreID));
                           }
                       }
                       else if ( self.applicationStoreID < 0 )
                       {
                           NSLog( @"Could not find this application on iTunes" );
                       }
                   }
               }
               else if (statusCode >= 400)
               {
                   //http error
                   NSString *message = [NSString stringWithFormat:@"The server returned a %@ error", @(statusCode)];
                   error = [NSError errorWithDomain:@"HTTPResponseErrorDomain" code:statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
               }

               if ( self.applicationStoreID > 0 )
               {
                   //show prompt
                   [self performSelectorOnMainThread:@selector(promptToRate:) withObject:object waitUntilDone:YES];
               }
               self->_background_check = NO;
           }];
        [task resume];
    }
}

- (void)setAppStoreIDOnMainThread:(NSString *)appStoreIDString
{
    self.applicationStoreID = [appStoreIDString integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:self.applicationStoreID forKey:kRateApplicationStoreID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSURL *) ratingsURL
{
    if ( self.applicationStoreID < 1 )
        return nil;
    return [NSURL URLWithString:[NSString stringWithFormat:rateAppStoreURLFormat, @(self.applicationStoreID)]];
}

- (void) promptToRate:(id)object
{
    if ( gDisablePrompt )
        return;
    if ( self.applicationStoreID < 1 )
    {
        //show prompt
        [self checkForConnectivityInBackground:object];
        return;
    }
    if ( object != nil && [object isKindOfClass:[NSNumber class]] && [object boolValue] )
    {
        [self rateMe];
        return;
    }
    
    gDisablePrompt = YES;

    NSString * msg = [NSString stringWithFormat:LOC( @"If you enjoy using %@ please take a minute to rate it."), self.applicationName ];
    NSString * title = [NSString stringWithFormat:LOC( @"Rate %@"), self.applicationName];
    NSString * rateApp = [NSString stringWithFormat:LOC( @"Rate %@ Now"), self.applicationName];

    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * pogo = [UIAlertAction actionWithTitle:rateApp style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                            {
                                [self rateMe];
                                gDisablePrompt = NO;
                            }];
    [alert addAction:pogo];

    UIAlertAction * cancel = [UIAlertAction actionWithTitle:LOC( @"Remind Me Later" ) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                              {

                                  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                                  [defaults setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:kRateApplicationInstallDate];
                                  [defaults synchronize];
                                  gDisablePrompt = NO;
                              }];
    [alert addAction:cancel];
    
    UIAlertAction * nomore = [UIAlertAction actionWithTitle:LOC( @"Don't Ask Again" ) style:UIAlertActionStyleDestructive handler:^(UIAlertAction
                                                                                                                                       * action)
                              {
                                  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                                  [defaults setBool:YES forKey:kRateApplicationDontPrompt];
                                  [defaults synchronize];
                                  gDisablePrompt = NO;
                              }];
    [alert addAction:nomore];
    [alert show:YES completion:nil];
}

- (void) rateMe
{
    NSURL * storeURL = [self ratingsURL];
    if ( storeURL == nil )
    {
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:self.ratingsURL])
    {
        [[UIApplication sharedApplication] openURL:self.ratingsURL options:@{} completionHandler:nil];
        [self setAppRated:YES];
    }
    else
    {
        NSLog( @"Unable to open ratings URL %@", storeURL );
    }
}

- (void) dealloc
{
    self.appStoreCountry = nil;
    self.applicationVersion = nil;
    self.applicationName = nil;
    self.applicationBundleID = nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end
