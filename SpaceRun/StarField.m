//
//  StarField.m
//  SpaceRun
//
//  Created by B.J. Ray on 8/15/14.
//  Copyright (c) 2014 109Software. All rights reserved.
//

#import "StarField.h"

@interface StarField ()
@property (nonatomic)BOOL galaxyExits;
@end

@implementation StarField
- (instancetype)init {
    if (self = [super init]) {
        __weak StarField *weakSelf = self;
        SKAction *update =[SKAction runBlock:^{
            if (arc4random_uniform(10) < 3) {
                [weakSelf launchStar];
            }
            if (arc4random_uniform(1000) < 25) {
                [weakSelf launchGalaxy];
            }
        }];
        SKAction *delay = [SKAction waitForDuration:0.01];
        SKAction *updateLoop = [SKAction sequence:@[delay, update]];
        [self runAction:[SKAction repeatActionForever:updateLoop]];
    }
    return self;
}


- (void)launchStar {
    CGFloat randX = arc4random_uniform(self.scene.size.width);
    CGFloat maxY = self.scene.size.height;
    CGPoint randomStart = CGPointMake(randX, maxY);
    
    SKSpriteNode *star = [SKSpriteNode spriteNodeWithImageNamed:@"shootingstar"];
    star.position = randomStart;
    star.size = CGSizeMake(2, 10);
    star.alpha = 0.1 + (arc4random_uniform(10) / 10.0f);
    [self addChild:star];
    
    CGFloat destY = 0 - self.scene.size.height - star.size.height;
    CGFloat duration = 0.5 + arc4random_uniform(5) / 10.0f;
    SKAction *move = [SKAction moveByX:0 y:destY duration:duration];
    SKAction *remove = [SKAction removeFromParent];
    [star runAction:[SKAction sequence:@[move, remove]]];
}

- (void)launchGalaxy {
    if (!self.galaxyExits) {
        u_int32_t dice = arc4random_uniform(100);
        if (dice < 15) {
//            CGFloat quarterX = self.scene.size.width / 4;
            CGFloat sideSize = 50 + arc4random_uniform(450);
            CGFloat maxX = self.scene.size.width;
            CGFloat randX = arc4random_uniform(maxX);
//            CGFloat randX = arc4random_uniform(maxX + (quarterX * 2)) - quarterX;
            CGFloat maxY = self.scene.size.height + sideSize/2;
            CGPoint randomStart = CGPointMake(randX, maxY);
            
            NSUInteger index = arc4random_uniform(3) + 1;
            NSString *galaxyName = [NSString stringWithFormat:@"galaxy%lu.png", (unsigned long)index];
            NSLog(@"galaxy with name: %@", galaxyName);
            SKSpriteNode *galaxy = [SKSpriteNode spriteNodeWithImageNamed:galaxyName];
            
            
            galaxy.position = randomStart;
            galaxy.size = CGSizeMake(sideSize, sideSize);
            galaxy.alpha = 0.3 + (arc4random_uniform(6) / 10.0f);
            //        galaxy.alpha = 0.3;
            galaxy.name = @"galaxy";
            self.galaxyExits = YES;
            NSLog(@"Add galaxy!");
            [self addChild:galaxy];
            
            CGFloat destY = 0 - maxY - galaxy.size.height/2;
            CGFloat duration = 20 + arc4random_uniform(10); //0.1 + arc4random_uniform(10) / 10.0f;
            SKAction *move = [SKAction moveByX:0 y:destY duration:duration];

            SKAction *remove = [SKAction removeFromParent];
            [galaxy runAction:[SKAction sequence:@[move, remove]] completion:^{
                self.galaxyExits = NO;
                NSLog(@"clear galaxy!");
            }];
//            [galaxy runAction:[SKAction sequence:@[move, remove, clear]]];
            
        }
    }
    
    
}
@end
