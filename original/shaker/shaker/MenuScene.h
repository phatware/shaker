//
//  MenuScene.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/23/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#define kMenuButtonRecipeList       101
#define kMenuButtonSettings         102
#define kMenuButtonThumbsUp         103
#define kMenuButtonThumbsDown       104


@protocol MenuSceneProtocl <NSObject>

- (void) menuSelected:(NSString *)name;
- (void) buttonPressed:(UIButton *)button;

@end


@interface MenuScene : SKScene

- (instancetype)initWithSize:(CGSize)size inView:(SKView *)view;

@property (nonatomic, weak) id<MenuSceneProtocl> mydelegate;

@end
