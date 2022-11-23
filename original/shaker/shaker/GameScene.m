//
//  GameScene.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/14/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "GameScene.h"
#import "utils.h"
#import "SoundManager.h"
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS


@interface  GameScene()
{
    BOOL    _shaking;
    CGSize  board_size;
}

@property (nonatomic, strong ) WKWebView * webview;
@property (nonatomic, strong ) SKSpriteNode * glass;
@property (nonatomic, strong ) SKSpriteNode * board;
@property (nonatomic, strong ) Sound * sound_pour;
@property (nonatomic, strong ) Sound * music;
@property (nonatomic, strong ) NSArray *  buttons;
@property (nonatomic, strong ) NSTimer *  idletimer;

@end

#define BUTTON_SIZE         ((self.frame.size.height > 700) ? 44 : 40)

@implementation GameScene

- (instancetype)initWithSize:(CGSize)size inView:(SKView *)view
{
    self = [super initWithSize:size];
    if ( self )
    {
        self.backgroundColor = [UIColor blackColor];
        
        SKSpriteNode * backnode = [SKSpriteNode spriteNodeWithImageNamed:@"wall"];
        backnode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:backnode];
        
        self.glass = [SKSpriteNode spriteNodeWithImageNamed:@"shaker"];
        [self addChild:self.glass];

        // self.sound_shake = [Sound soundNamed:@"shake.aifc"];
        self.sound_pour = [Sound soundNamed:@"quick-pour.mp3"];
        self.music = [Sound soundNamed:@"LochNess.wav"];
        
        float volume = [[NSUserDefaults standardUserDefaults] floatForKey:kShakerMusicVolume];
        if ( volume <= 0.0 )
        {
            volume = 0.6;
            [[NSUserDefaults standardUserDefaults] setFloat:volume forKey:kShakerMusicVolume];
            [SoundManager sharedManager].musicVolume = volume;
        }

        NSString * strImageName = @"blackboard1";
        CGFloat height = MAX( [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        if ( height > 560 )
            strImageName = @"blackboard2";
        if ( height > 660 )
            strImageName = @"blackboardHD1";
        if ( height > 700 )
            strImageName = @"blackboardHD";
        self.board = [SKSpriteNode spriteNodeWithImageNamed:strImageName];

        SKSpriteNode * menu = [SKSpriteNode spriteNodeWithImageNamed:@"menu"];
        menu.position = CGPointMake( self.frame.size.width - menu.size.width/2.0 - 10,
                                    self.frame.size.height - menu.size.height/2.0 - (height > 800 ? 40 : 10) );
        menu.name = @"MENU";
        [self addChild:menu];
        
        if ( self.buttons == nil )
        {
            NSMutableArray * btnArray = [[NSMutableArray alloc] initWithCapacity:kGameCommandTotal];
            for ( int i = 0; i < kGameCommandTotal; i++ )
            {
                UIButton * button = [UIButton buttonWithType:(UIButtonTypeSystem)];
                button.hidden = YES;
                button.tag = i+kGameCommandShare;
                button.opaque = NO;
                button.enabled = NO;
                button.backgroundColor = [UIColor clearColor];
                [button addTarget:self action:@selector(buttonPressed:) forControlEvents:(UIControlEventTouchDown)];
                [view addSubview:button];
                [btnArray addObject:button];
            }
            self.buttons = (NSArray *)btnArray;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(soundFinished:)
                                                 name:SoundDidFinishPlayingNotification
                                               object:nil];
    

    return self;
}

-(void)didMoveToView:(SKView *)view
{
    self.glass.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.glass.alpha = 0.2;
    _shaking = NO;
    
    self.board.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) );
    board_size = self.board.size;
    self.current_recipe  = nil;

    [self.glass removeAllActions];
    [self performSelector:@selector(flicker:) withObject:self.glass afterDelay:2.0];
    
    if ( self.music )
        self.music.currentTime = 0.0;
    self.shakeview.ignoreEvents = NO;
    [self.shakeview becomeFirstResponder];
}

- (void)willMoveFromView:(SKView *)view
{
    self.shakeview.ignoreEvents = YES;
    [[SoundManager sharedManager] stopMusic:YES];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self killTimer];
}

- (void) buttonPressed:(UIButton *)sender
{
    if ( self.mydelegate && [self.mydelegate respondsToSelector:@selector(buttonPressed:recipe :)] )
    {
        [self.mydelegate buttonPressed:sender recipe:self.current_recipe ];
    }
}

- (void) flicker:(SKSpriteNode *)node
{
    SKAction * fadeOut =[SKAction fadeAlphaTo:0.3 duration:0.08];
    SKAction * fadeIn =[SKAction fadeAlphaTo:1.0 duration:0.08];
    SKAction * scaleSmall =[SKAction scaleTo:0.997 duration:0.03];
    SKAction * scaleBig =[SKAction scaleTo:1.0 duration:0.03];
    SKAction * wait = [SKAction waitForDuration:0.1 withRange:0.4];
    SKAction * wait2 = [SKAction waitForDuration:4.0 withRange:7.0];
    SKAction * wait3 = [SKAction waitForDuration:0.05 withRange:0.2];
    SKAction * wait4 = [SKAction waitForDuration:1.0 withRange:2.5];
    
    SKAction * sound1 = [SKAction playSoundFileNamed:@"buzz1.wav" waitForCompletion:NO];
    SKAction * sound2 = [SKAction playSoundFileNamed:@"buzz2.wav" waitForCompletion:NO];
    
    SKAction * seq = [SKAction sequence:@[sound1, fadeOut, scaleSmall, wait3, fadeIn, scaleBig, wait4, sound2, fadeOut, scaleSmall, wait, fadeIn, scaleBig, wait2]];
       
    [node removeAllActions];
    [node runAction:[SKAction repeatActionForever:seq]];
    [self.shakeview becomeFirstResponder];
}

- (void) startShake:(UIView *)sender
{
    // TODO...
    if ( _shaking )
        return;
    
    // [self runAction:[SKAction playSoundFileNamed:@"sfx.wav" waitForCompletion:NO]];
}

- (void) killTimer
{
    if ( nil != self.idletimer )
    {
        [self.idletimer invalidate];
        self.idletimer = nil;
    }
}

- (void) idleTimer:(NSTimer *)timer
{
    if ( self.idletimer )
    {
        [self killTimer];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void) soundFinished:(NSNotification *)notification
{
    Sound * sound = notification.object;
    if ( sound && [sound isEqual:self.sound_pour] && [[NSUserDefaults standardUserDefaults] boolForKey:kShakerPlayMusic] )
    {
        [[SoundManager sharedManager] playMusic:self.music looping:YES fadeIn:YES];
    }
}

- (void) didShake:(UIView *)sender
{
    if ( _shaking )
    {
        NSLog( @"shaking..." );
        return;
    }
    [[SoundManager sharedManager] playSound:self.sound_pour looping:NO fadeIn:YES];

    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self killTimer];
    self.idletimer = [NSTimer scheduledTimerWithTimeInterval:120.0 target:self
                                                    selector:@selector(idleTimer:) userInfo:nil repeats:NO];
    
    @autoreleasepool
    {
        
        CGRect webrect =  CGRectMake( 16, self.board.frame.origin.y + 20, self.frame.size.width - 32, 1.0 );
        webrect.size.height = board_size.height - ((self.frame.size.height > 700) ? 110 : 90);
        
        _shaking = YES;

        if ( self.webview )
        {
            for ( UIButton * btn in self.buttons )
            {
                btn.hidden = YES;
                btn.enabled = NO;
            }
            
            [self.board removeFromParent];
            [self.webview removeFromSuperview];
            self.webview = nil;
        }

        // configure web view - disaable zoom and ebable only link detector
        NSString * source = @"var meta = document.createElement('meta');"
                        @"meta.name = 'viewport';"
                        @"meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';"
                        @"var head = document.getElementsByTagName('head')[0];"
                        @"head.appendChild(meta);";
        WKUserScript * script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:true];
        WKUserContentController * contentController = [[WKUserContentController alloc] init];
        [contentController addUserScript:script];
        WKWebViewConfiguration * theConfiguration = [[WKWebViewConfiguration alloc] init];
        theConfiguration.dataDetectorTypes = WKDataDetectorTypeLink;
        theConfiguration.userContentController = contentController;
        WKPreferences * preferences = [[WKPreferences alloc] init];
        preferences.minimumFontSize = 14.0;
        theConfiguration.preferences = preferences;
        
        self.webview = [[WKWebView alloc] initWithFrame:webrect configuration:theConfiguration];
        self.webview.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.webview.autoresizesSubviews = YES;
        self.webview.navigationDelegate = self;
        self.webview.backgroundColor = [UIColor clearColor];
        self.webview.opaque = NO;
        self.webview.alpha = 0.0;
        [self.view addSubview:self.webview];
        
        // dim glass and stop animation
        [self.glass removeAllActions];
        self.glass.alpha = 0.2;
        //[self.glass runAction:[SKAction fadeAlphaTo:0.0 duration:0.4] completion:^{
         //   [self.glass removeFromParent];
        //}];
        
        CGFloat y = self.board.frame.origin.y + board_size.height - ((self.frame.size.height > 700) ? 66 : 55);
        CGFloat x = (self.frame.size.width > 350) ? 28 : 20;
        CGFloat offset = ((self.frame.size.width > 400) ? 34.5 : 30);
        if ( self.frame.size.width < 350 )
            offset = 20;
        CGRect btnRect = CGRectMake( x, y, BUTTON_SIZE, BUTTON_SIZE );
        for ( UIButton * btn in self.buttons )
        {
            btn.frame = btnRect;
            btnRect.origin.x += (BUTTON_SIZE + offset);
            btn.hidden = NO;
            btn.enabled = YES;
        }
        
        self.board.size = CGSizeMake( 1.0, 1.0 );
        [self addChild:self.board];
        SKAction * asize = [SKAction resizeToWidth:board_size.width height:board_size.height duration:0.5];
        [self.board runAction:asize completion:^{}];

        // search in the background thread
        NSString * html;
        sqlite3_int64 recid = [self.coctails findRandomRecipe];
        self.current_recipe = recid == 0 ? nil : [self.coctails getRecipe:recid noImage:NO];
        if (self.current_recipe == nil)
        {
            html = @"<html> <head>"
                    "<style type=\"text/css\">\nbody {font-family: \"Chalkduster\"; font-size: 16 px;}\n-webkit-touch-callout: none;\n</style>"
                    "<style type=\"text/css\">\na {color:white; font-size: 18px;}</style>"
                    "</head><body> <font color=\"#CC77FF\"> <p> Could not find any recipes with selected ingredients. Please shake again or select more ingredients. </p>"
                    "<p><br></p><table style=\"width:100%%\"> <tr> <td align=\"left\"><a href=\"http://done\">SHAKE AGAIN!</a></td>"
                    "<td align=\"right\"><a href=\"http://main\">MENU</a></td> </tr> </table> </body></html>";
        }
        else
        {
            html = [NSString stringWithFormat:@"<html> <head>"
                           "<style type=\"text/css\">\nbody {font-family: \"Chalkduster\"; font-size: 14px;}\n-webkit-touch-callout: none;\n</style>"
                           "<style type=\"text/css\">\na {color:white; font-size: 16px;}</style>"
                           "</head><body> <font color=\"#CC77FF\"> <h3>%@</h3>"
                           "<font color=\"#AACCFF\"><p><b>Glass:</b></p> <ul><li>%@</ul></li> <p><b>Ingredients:</b></p> <p>%@</p>"
                           "<p><br>%@</p>"
                           "<table style=\"width:100%%\"> <tr> <td align=\"left\"><a href=\"http://done\">SHAKE AGAIN!</a></td>"
                           "<td align=\"right\"><a href=\"http://main\">MENU</a></td> </tr> </table> </body></html>",
                           [self.current_recipe  objectForKey:@"name"],
                           [self.current_recipe  objectForKey:@"glass"],
                           [self.current_recipe  objectForKey:@"ingredients"],
                           [self.current_recipe  objectForKey:@"instructions"]];
        }
        [self.webview loadHTMLString:html baseURL:nil];
        [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
            self.webview.alpha = 1.0;
        } completion:^(BOOL finished) {
            self->_shaking = NO;
        }];
        
#ifdef GOOGLE_ANALYTICS
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                         kFIRParameterItemID:[NSString stringWithFormat:@"id_Event_%@", (self.current_recipe == nil) ? @"" : [self.current_recipe  objectForKey:@"name"]],
                                         kFIRParameterContentType:@"Game"
                                         }];
#endif // GOOGLE_ANALYTICS
    }
}

- (void)webView:(WKWebView *)inView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
    @synchronized(self)
    {
        NSURL * u = [navigationAction.request URL];
        __block NSString * s = [u absoluteString];
        if ( self.webview && navigationAction.navigationType == WKNavigationTypeLinkActivated && ([s caseInsensitiveCompare:@"http://done/"] == NSOrderedSame ||
                                                                                      [s caseInsensitiveCompare:@"http://main/"] == NSOrderedSame) )
        {
            for ( UIButton * btn in self.buttons )
            {
                btn.hidden = YES;
                btn.enabled = NO;
            }
            
            [[SoundManager sharedManager] stopAllSounds:YES];
            [[SoundManager sharedManager] stopMusic:YES];
            [self.webview removeFromSuperview];
            self.webview = nil;
            self.current_recipe  = nil;

            SKAction * asize = [SKAction resizeToWidth:1.0 height:1.0 duration:0.5];
            [self.board runAction:asize completion:^{
                self.board.size = self->board_size;
                [self.board removeFromParent];
                if ( [s caseInsensitiveCompare:@"http://main/"] == NSOrderedSame )
                {
                    // go to main menu
                    if ( self.mydelegate && [self.mydelegate respondsToSelector:@selector(showMainMenu)] )
                    {
                        self.shakeview.ignoreEvents = YES;
                        [self.mydelegate showMainMenu];
                        return;
                    }
                }
            }];
            [self performSelector:@selector(flicker:) withObject:self.glass afterDelay:1.0];
        }
    }
    [self.shakeview becomeFirstResponder];
    if (navigationAction.navigationType == WKNavigationTypeOther) // || navigationAction.navigationType == WKNavigationTypeLinkActivated)
        decisionHandler(WKNavigationActionPolicyAllow);
    else
        decisionHandler(WKNavigationActionPolicyCancel);
}

-(void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
}

- (BOOL)becomeFirstResponder
{
    return [self.shakeview becomeFirstResponder];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint   location = [touch locationInNode:self];
    SKNode *  node = [self nodeAtPoint:location];
    
    NSLog( @"Node name: %@", node.name );    
    if ( [node.name isEqualToString:@"MENU"] )
    {
        [[SoundManager sharedManager] stopAllSounds:YES];
        if ( self.mydelegate && [self.mydelegate respondsToSelector:@selector(showMainMenu)] )
        {
            self.shakeview.ignoreEvents = YES;
            [self.mydelegate showMainMenu];
            return;
        }
    }
    [self.shakeview becomeFirstResponder];
}

@end
