//
//  GameScene.h
//  shaker
//

//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <WebKit/WebKit.h>
#import "UserDatabase.h"
#import "CoctailsDatabase.h"
#import "ShakeView.h"

typedef enum
{
    kGameCommandShare = 1,
    kGameCommandNote = 2,
    kGameCommandPhoto = 3,
    kGameCommandShopping = 4,
    kGameCommandRate = 5,
    kGameCommandTotal = 5
} kGameCommand;


@protocol GameSceneProtocl <NSObject>

- (BOOL) buttonPressed:(UIButton *)button recipe :(NSDictionary *)recpie;
- (void) showMainMenu;

@end

@interface GameScene : SKScene <WKNavigationDelegate, ShakeViewPritocol>

- (instancetype)initWithSize:(CGSize)size inView:(SKView *)view;

@property (nonatomic, strong) CoctailsDatabase * coctails;
@property (nonatomic, strong) UserDatabase * userdata;
@property (nonatomic, strong) ShakeView * shakeview;
@property (nonatomic, weak) id<GameSceneProtocl> mydelegate;
@property (nonatomic, strong ) NSDictionary * current_recipe ;

@end
