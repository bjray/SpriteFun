//
//  MyScene.h
//  SpaceRun
//

//  Copyright (c) 2014 109Software. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface MyScene : SKScene
@property (nonatomic, copy) dispatch_block_t endGameCallback;
@property (nonatomic) BOOL easyMode;
@end
