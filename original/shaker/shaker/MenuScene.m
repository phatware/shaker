//
//  MenuScene.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/23/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//


#import "MenuScene.h"
#import "utils.h"

#define GAP1                23
#define GAP2                48
#define LEFT_MARGIN         60

#define SMALL_FONT_SIZE     14.5
#define LARGE_FONT_SIZE     36
#define MED_FONT_SIZE       26

@interface  MenuScene()
{
    BOOL    showDisclamer;
}

@property (nonatomic, strong ) UIButton * buttonList;
@property (nonatomic, strong ) UIButton * buttonSet;

@end

@implementation MenuScene

- (instancetype)initWithSize:(CGSize)size inView:(SKView *)view
{
    self = [super initWithSize:size];
    if ( self )
    {
        UIButton * button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.tag = kMenuButtonRecipeList;
        button.showsTouchWhenHighlighted = YES;
        button.opaque = NO;
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:(UIControlEventTouchDown)];
        [view addSubview:button];
        self.buttonList = button;
        
        button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.showsTouchWhenHighlighted = YES;
        button.tag = kMenuButtonSettings;
        button.opaque = NO;
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:(UIControlEventTouchDown)];
        [view addSubview:button];
        self.buttonSet = button;
        
        showDisclamer = (![[NSUserDefaults standardUserDefaults] boolForKey:kShakerHideDisclaimer]);
    }
    return self;
}

-(void)didMoveToView:(SKView *)view
{
    self.backgroundColor = [UIColor blackColor];
    CGFloat top = self.frame.size.height - 160;
    CGFloat gap = GAP2;
    CGFloat gap1 = GAP1;
    CGFloat largeFontSize = LARGE_FONT_SIZE;
    CGFloat smallFontSize = SMALL_FONT_SIZE;
    CGFloat medFontSize = MED_FONT_SIZE;
    CGFloat buttonSize = 46;
    CGFloat buttonX = 66, buttonX1 = 302, buttonTop = 20;
    
    // iPhone scressn
    // 320 x 480 (640 x 960) @2x
    // 320 x 568 (640 x 1136) @2x
    // 375 x 667 (750 x 1334) @2x
    // 414 x 736 (1242 × 2208) @3x
    
    // TODO: add NEW
    // 375 x 812 (1125 x 2436) @3x
    // 414 x 896 (838 x 1792) @2x
    // 414 x 896 (1242 x 2688) @3x

    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat scale = [UIScreen mainScreen].scale;
    NSString * strImageName = @"menuview1";
    if ( height == 568.0f )
        strImageName = @"menuview";
    else if ( height == 667.0f )
        strImageName = @"menuviewHD1";
    else if ( height == 736.0f )
        strImageName = @"menuHD";
    // TODO: add images
    else if ( height == 812.0 )
        strImageName = @"menuHD";
    else if ( height > 840.0 && scale == 2.0 )
        strImageName = @"menuHD";
    else if ( height > 840.0 && scale == 3.0 )
        strImageName = @"menuHD";

    height = MAX( [UIScreen mainScreen].bounds.size.width, height);
    if ( height > 800 )
    {
        // TODO:
        top = self.frame.size.height - 160;
    }
    else if ( height > 700 )
    {
        top = self.frame.size.height - 160;
    }
    else if ( height > 660 )
    {
        top = self.frame.size.height - 135;
        gap -= 3;
        buttonX = 54;
        buttonX1 = 276;
    }
    else
    {
        largeFontSize -= 5;
        smallFontSize -= 3;
        medFontSize -= 5;
        gap -= 10;
        gap1 -= 3;
        buttonSize = 35;
        top = self.frame.size.height - 108;
        buttonX = 42;
        buttonX1 = 244;
        buttonTop = 28;
    }
    
    SKSpriteNode * back = [SKSpriteNode spriteNodeWithImageNamed:strImageName];
    back.size = self.frame.size;
    back.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    [self addChild:back];
    
    SKLabelNode * label1 = [SKLabelNode labelNodeWithText:LOC( @"Bar" )];
    label1.fontName = @"Chalkduster";
    label1.fontSize = largeFontSize;
    label1.position = CGPointMake(CGRectGetMidX(self.frame), top );
    label1.name = @"BAR";
    [self addChild:label1];
    
    top -= gap1;
    
    SKLabelNode * label2 = [SKLabelNode labelNodeWithText:LOC( @"Ingredients found in most bars" )];
    label2.fontName = @"Chalkduster";
    label2.fontSize = smallFontSize;
    label2.fontColor = [UIColor colorWithRed:(175.0/255.0) green:1.0 blue:(175.0/255.0) alpha:1.0];
    label2.position = CGPointMake(CGRectGetMidX(self.frame), top );
    label2.name = @"BAR";
    [self addChild:label2];
    
    top -= gap;
    
    SKLabelNode * label3 = [SKLabelNode labelNodeWithText:LOC( @"Top 20" )];
    label3.fontName = @"Chalkduster";
    label3.fontSize = largeFontSize;
    label3.name = @"TOP10";
    label3.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label3];
    
    top -= gap1;

    SKLabelNode * label4 = [SKLabelNode labelNodeWithText:LOC( @"20 most used ingredients" )];
    label4.fontName = @"Chalkduster";
    label4.fontSize = smallFontSize;
    label4.name = @"TOP10";
    label4.fontColor = [UIColor colorWithRed:(181.0/255.0) green:(179.0/255.0) blue:(248.0/255.0) alpha:1.0];
    label4.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label4];
    
    top -= gap;
    
    SKLabelNode * label5 = [SKLabelNode labelNodeWithText:LOC( @"Top 10" )];
    label5.fontName = @"Chalkduster";
    label5.fontSize = largeFontSize;
    label5.name = @"TOP5";
    label5.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label5];
    
    top -= gap1;
    
    SKLabelNode * label6 = [SKLabelNode labelNodeWithText:LOC( @"10 most used ingredients" )];
    label6.fontName = @"Chalkduster";
    label6.fontSize = smallFontSize;
    label6.name = @"TOP5";
    label6.fontColor = [UIColor colorWithRed:(250.0/255.0) green:(243.0/255.0) blue:(131.0/255.0) alpha:1.0];
    label6.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label6];

    top -= gap;
    
    SKLabelNode * label7 = [SKLabelNode labelNodeWithText:LOC( @"Designated Driver" )];
    label7.fontName = @"Chalkduster";
    label7.fontSize = medFontSize;
    label7.name = @"NON";
    label7.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label7];
    
    top -= gap1;
    
    SKLabelNode * label8 = [SKLabelNode labelNodeWithText:LOC( @"Non-alcoholic beverages" )];
    label8.fontName = @"Chalkduster";
    label8.fontSize = smallFontSize;
    label8.name = @"NON";
    label8.fontColor = [UIColor colorWithRed:(166.0/255.0) green:(213.0/255.0) blue:(246.0/255.0) alpha:1.0];
    label8.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label8];

    top -= gap;
    
    SKLabelNode * label9 = [SKLabelNode labelNodeWithText:LOC( @"Make your own" )];
    label9.fontName = @"Chalkduster";
    label9.fontSize = medFontSize+4;
    label9.name = @"MAKE";
    label9.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label9];
    
    top -= gap1;
    
    SKLabelNode * label10 = [SKLabelNode labelNodeWithText:LOC( @"Choose ingredients you have" )];
    label10.fontName = @"Chalkduster";
    label10.fontSize = smallFontSize;
    label10.name = @"MAKE";
    label10.fontColor = [UIColor colorWithRed:1.0 green:(182.0/255.0) blue:(182.0/255.0) alpha:1.0];
    label10.position = CGPointMake(CGRectGetMidX(self.frame), top );
    [self addChild:label10];
    
    CGRect bf = CGRectMake( buttonX, (view.frame.size.height - top) + buttonTop, buttonSize, buttonSize );
    self.buttonList.frame = bf;
    bf.origin.x = buttonX1;
    self.buttonSet.frame = bf;
    
    top -= gap1 * 2.0;

    SKSpriteNode * up = [SKSpriteNode spriteNodeWithImageNamed:@"thumb_up"];
    up.position = CGPointMake(CGRectGetMidX(self.frame) - 30, top );
    up.name = @"UP";
    [self addChild:up];
    
    SKSpriteNode * down = [SKSpriteNode spriteNodeWithImageNamed:@"thumb_down"];
    down.position = CGPointMake(CGRectGetMidX(self.frame) + 30, top );
    down.name = @"DOWN";
    [self addChild:down];
    
    if ( showDisclamer )
    {
        CGFloat offset = 40;
        NSString * dm = @"disclaimer";
        if ( [UIScreen mainScreen].bounds.size.height >= 667.0f && [UIScreen mainScreen].scale >= 2.0f )
            dm = @"disclaimer3";
        if ( [UIScreen mainScreen].bounds.size.height >= 800.0f )
            offset = 180;
        SKSpriteNode * disclaimer = [SKSpriteNode spriteNodeWithImageNamed:dm];
        disclaimer.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.size.height - disclaimer.size.height/2.0 - offset );
        disclaimer.alpha = 0.0;
        disclaimer.name = @"DISC";
        SKAction * asize = [SKAction fadeAlphaTo:1.0 duration:1.0];
        [disclaimer runAction:asize completion:^{
        }];
        [self addChild:disclaimer];
        showDisclamer = NO;
    }
}

- (void) buttonPressed:(UIButton *)button
{
    if ( self.mydelegate && [self.mydelegate respondsToSelector:@selector(buttonPressed:)] )
    {
        [self.mydelegate buttonPressed:button];
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint   location = [touch locationInNode:self];
    SKNode *  node = [self nodeAtPoint:location];
    
    NSLog(@"Node name: %@", node.name);    
    if ( [node.name isEqualToString:@"DISC"] )
    {
        SKAction * asize = [SKAction fadeAlphaTo:0.0 duration:1.0];
        [node runAction:asize completion:^{
            [node removeFromParent];
        }];
        return;
    }
    else if ( [node.name isEqualToString:@"UP"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"DOWN"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"BAR"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"TOP5"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"TOP10"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"MAKE"] )
    {
        
    }
    else if ( [node.name isEqualToString:@"NON"] )
    {
        
    }
    else
    {
        return;
    }
    if ( self.mydelegate && [self.mydelegate respondsToSelector:@selector(menuSelected:)] )
    {
        [self.mydelegate menuSelected:node.name ];
    }
}


@end
