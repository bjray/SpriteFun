//
//  MyScene.m
//  SpaceRun
//
//  Created by B.J. Ray on 8/10/14.
//  Copyright (c) 2014 109Software. All rights reserved.
//

#define kSHOT_TIME 0.5
#define kPHOTON_SPEED 0.5

#define kOBSTACLE_FREQUENCY 15
#define kASTEROID_MIN_SPEED 3
#define kASTEROID_SPEED_DELTA 4

#define kENEMY_FREQUENCY 20
#define kENEMY_SPEED 7

#define kPOWER_UP_DURATION 5
#define kPOWER_UP_FREQUENCY 5

#import "MyScene.h"
#import "StarField.h"
#import "SKEmitterNode+Extensions.h"

@interface MyScene ()
@property (nonatomic, weak) UITouch *shipTouch;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) NSTimeInterval lastShotFireTime;
@property (nonatomic, strong) SKAction *shootSound;
@property (nonatomic, strong) SKAction *shipExplodeSound;
@property (nonatomic, strong) SKAction *obstacleExplodeSound;
@property (nonatomic, strong) SKEmitterNode *shipExplodeTemplate;
@property (nonatomic, strong) SKEmitterNode *obstacleExplodeTemplate;
@property (nonatomic) CGFloat shipFireRate;
@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor blackColor];
        StarField *starField = [StarField node];
        [self addChild:starField];
        
        NSString *name = @"Spaceship.png";
        SKSpriteNode *ship = [SKSpriteNode spriteNodeWithImageNamed:name];
        ship.position = CGPointMake(size.width / 2, size.height / 2);
        ship.size = CGSizeMake(40.0, 40.0);
        ship.name = @"ship";
        [self addChild:ship];
        
        SKEmitterNode *thrust = [SKEmitterNode rcw_nodeWithFile:@"thrust.sks"];
        thrust.position = CGPointMake(0, -20);
        [ship addChild:thrust];
        
        self.shipExplodeTemplate = [SKEmitterNode rcw_nodeWithFile:@"shipExplode.sks"];
        self.obstacleExplodeTemplate = [SKEmitterNode rcw_nodeWithFile:@"obstacleExplode.sks"];
        
        
        self.shipFireRate = kPHOTON_SPEED;
        self.shootSound = [SKAction playSoundFileNamed:@"shoot.m4a" waitForCompletion:NO];
        self.obstacleExplodeSound = [SKAction playSoundFileNamed:@"obstacleExplode.m4a" waitForCompletion:NO];
        self.shipExplodeSound = [SKAction playSoundFileNamed:@"shipExplode.m4a" waitForCompletion:NO];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.shipTouch = [touches anyObject];
}

- (void)update:(NSTimeInterval)currentTime {
    if (self.lastUpdateTime == 0) {
        self.lastUpdateTime = currentTime;
    }
    NSTimeInterval timeDelta = currentTime - self.lastUpdateTime;
    
    if (self.shipTouch) {
        [self moveShipTowardPoint:[self.shipTouch locationInNode:self]
                      byTimeDelta:timeDelta];
        
        if (currentTime - self.lastShotFireTime > self.shipFireRate) {
            [self shoot];
            self.lastShotFireTime = currentTime;
        }
        
    }
    
    if (arc4random_uniform(1000) <= kOBSTACLE_FREQUENCY) {
        [self launchObstacle];
    }
    
    
    [self checkCollisions];
    self.lastUpdateTime = currentTime;
}

- (void)moveShipTowardPoint:(CGPoint)point byTimeDelta:(NSTimeInterval)timeDelta {
    CGFloat shipSpeed = 130;  //points per second
    SKNode *ship = [self childNodeWithName:@"ship"];
    CGFloat distanceLeft = sqrtf(pow(ship.position.x - point.x, 2) + pow(ship.position.y - point.y, 2));
    
    if (distanceLeft > 4) {
        CGFloat distanceToTravel = timeDelta * shipSpeed;
        CGFloat angle = atan2(point.y - ship.position.y, point.x - ship.position.x);
        CGFloat yOffset = distanceToTravel * sin(angle);
        CGFloat xOffset = distanceToTravel * cos(angle);
        ship.position = CGPointMake(ship.position.x + xOffset, ship.position.y + yOffset);
    }
}

- (void)shoot {
    SKNode *ship = [self childNodeWithName:@"ship"];
    
    SKSpriteNode *photon = [SKSpriteNode spriteNodeWithImageNamed:@"photon"];
    photon.name = @"photon";
    photon.position = ship.position;
    [self addChild:photon];
    
    SKAction *fly = [SKAction moveByX:0
                                    y:self.size.height+photon.size.height
                             duration:kPHOTON_SPEED];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *fireAndRemove = [SKAction sequence:@[fly, remove]];

    [photon runAction:fireAndRemove];
    
    [self runAction:self.shootSound];
}

- (void)dropAsteroid {
    CGFloat sideSize = 15 + arc4random_uniform(30);
    CGFloat maxX = self.size.width;
    CGFloat quarterX = maxX / 4;
    CGFloat startX = arc4random_uniform(maxX + (quarterX * 2)) - quarterX;
    CGFloat startY = self.size.height + sideSize;
    CGFloat endX = arc4random_uniform(maxX);
    CGFloat endY = 0 - sideSize;
    
    SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
    asteroid.size = CGSizeMake(sideSize, sideSize);
    asteroid.position = CGPointMake(startX, startY);
    asteroid.name = @"obstacle";
    [self addChild:asteroid];
    
    SKAction *move = [SKAction moveTo:CGPointMake(endX, endY) duration:[self asteroidFallRate]];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *travelAndRemove = [SKAction sequence:@[move, remove]];
    
    SKAction *spin = [SKAction rotateByAngle:3 duration:arc4random_uniform(2)+1];
    SKAction *spinForever = [SKAction repeatActionForever:spin];

    //group runs actions in parallel...
    SKAction *all = [SKAction group:@[spinForever, travelAndRemove]];
    [asteroid runAction:all];
}

- (void)dropEnemyShip {
    CGFloat sideSize = 30;
    CGFloat startX = arc4random_uniform(self.size.width - 40) + 20;
    CGFloat startY = self.size.height + sideSize;
    
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    
    //NOTE: Would be interesting to have them start smaller or bigger to simulate height
    //      and only hit when within 10% of the normal size, indicating on the same plane
    enemy.size = CGSizeMake(sideSize, sideSize);
    enemy.position = CGPointMake(startX, startY);
    enemy.name = @"obstacle";
    [self addChild:enemy];
    
    CGPathRef shipPath = [self buildEnemyShipMovementPath];
    SKAction *followPath = [SKAction followPath:shipPath
                                       asOffset:YES
                                   orientToPath:YES
                                       duration:kENEMY_SPEED];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *all = [SKAction sequence:@[followPath, remove]];
    [enemy runAction:all];
}

- (void)dropPowerUp {
    CGFloat sideSize = 30;
    CGFloat startX = arc4random_uniform(self.size.width-60) + 30;
    CGFloat startY = self.size.height + sideSize;
    CGFloat endY = 0 - sideSize;
    SKSpriteNode *powerup = [SKSpriteNode spriteNodeWithImageNamed:@"powerup"];
    powerup.name = @"powerup";
    powerup.size = CGSizeMake(sideSize, sideSize);
    powerup.position = CGPointMake(startX, startY);
    [self addChild:powerup];
    SKAction *move = [SKAction moveTo:CGPointMake(startX, endY) duration:6];
    SKAction *spin = [SKAction rotateByAngle:-1 duration:1];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *spinForever = [SKAction repeatActionForever:spin];
    SKAction *travelAndRemove = [SKAction sequence:@[move, remove]];
    SKAction *all = [SKAction group:@[spinForever, travelAndRemove]];
    [powerup runAction:all];
}

- (NSTimeInterval)asteroidFallRate {
    return kASTEROID_MIN_SPEED + arc4random_uniform(kASTEROID_SPEED_DELTA);
}

- (void)checkCollisions {
    SKNode *ship = [self childNodeWithName:@"ship"];
    
    [self enumerateChildNodesWithName:@"powerup" usingBlock:^(SKNode *powerUp, BOOL *stop) {
        if ([ship intersectsNode:powerUp]) {
            [powerUp removeFromParent];
            self.shipFireRate = 0.1;
            
            SKAction *powerDown = [SKAction runBlock:^{
                self.shipFireRate = kPHOTON_SPEED;
            }];
            
            SKAction *wait = [SKAction waitForDuration:kPOWER_UP_DURATION];
            SKAction *waitAndPowerDown = [SKAction sequence:@[wait, powerDown]];
            [ship removeActionForKey:@"waitAndPowerDown"];
            [ship runAction:waitAndPowerDown withKey:@"waitAndPowerDown"];
        }
    }];
    
    
    [self enumerateChildNodesWithName:@"obstacle" usingBlock:^(SKNode *obstacle, BOOL *stop) {
        if ([ship intersectsNode:obstacle]) {
            self.shipTouch = nil;
            [ship removeFromParent];
            [obstacle removeFromParent];
            [self runAction:self.shipExplodeSound];
            
            SKEmitterNode *explosion = [self.shipExplodeTemplate copy];
            explosion.position = ship.position;
            [explosion rcw_dieOutInDuration:0.3];
            [self addChild:explosion];
        }
        [self enumerateChildNodesWithName:@"photon" usingBlock:^(SKNode *photon, BOOL *stop) {
            if ([photon intersectsNode:obstacle]) {
                [photon removeFromParent];
                [obstacle removeFromParent];
                [self runAction:self.obstacleExplodeSound];
                
                SKEmitterNode *explosion = [self.obstacleExplodeTemplate copy];
                explosion.position = obstacle.position;
                [explosion rcw_dieOutInDuration:0.1];
                [self addChild:explosion];
                
                *stop = YES;
            }
        }];
    }];
}


- (void)launchObstacle {
    u_int32_t dice = arc4random_uniform(100);
    
    //method 1
    if (dice < kPOWER_UP_FREQUENCY) {
        [self dropPowerUp];
    } else if (dice < kENEMY_FREQUENCY) {
        [self dropEnemyShip];
    } else {
        [self dropAsteroid];
    }
    
//    //method 2
//    if (dice < 5) {
//        [self dropPowerUp];
//    }
//    if (dice <= kASTEROID_FREQUENCY) {
//        [self dropAsteroid];
//    }
//    
//    if (dice <= kENEMY_FREQUENCY) {
//        [self dropEnemyShip];
//    }
}

- (CGPathRef)buildEnemyShipMovementPath {
    
    //consider adding multiple different enemy paths...
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(0.5, -0.5)];
    [bezierPath addCurveToPoint: CGPointMake(-2.5, -59.5) controlPoint1: CGPointMake(0.5, -0.5) controlPoint2: CGPointMake(4.55, -29.48)];
    [bezierPath addCurveToPoint: CGPointMake(-27.5, -154.5) controlPoint1: CGPointMake(-9.55, -89.52) controlPoint2: CGPointMake(-43.32, -115.43)];
    [bezierPath addCurveToPoint: CGPointMake(30.5, -243.5) controlPoint1: CGPointMake(-11.68, -193.57) controlPoint2: CGPointMake(17.28, -186.95)];
    [bezierPath addCurveToPoint: CGPointMake(-52.5, -379.5) controlPoint1: CGPointMake(43.72, -300.05) controlPoint2: CGPointMake(-47.71, -335.76)];
    [bezierPath addCurveToPoint: CGPointMake(54.5, -449.5) controlPoint1: CGPointMake(-57.29, -423.24) controlPoint2: CGPointMake(-8.14, -482.45)];
    [bezierPath addCurveToPoint: CGPointMake(-5.5, -348.5) controlPoint1: CGPointMake(117.14, -416.55) controlPoint2: CGPointMake(52.25, -308.62)];
    [bezierPath addCurveToPoint: CGPointMake(10.5, -494.5) controlPoint1: CGPointMake(-63.25, -388.38) controlPoint2: CGPointMake(-14.48, -457.43)];
    [bezierPath addCurveToPoint: CGPointMake(0.5, -559.5) controlPoint1: CGPointMake(23.74, -514.16) controlPoint2: CGPointMake(6.93, -537.57)];
    [bezierPath addCurveToPoint: CGPointMake(-2.5, -644.5) controlPoint1: CGPointMake(-5.2, -578.93) controlPoint2: CGPointMake(-2.5, -644.5)];
    
    return bezierPath.CGPath;
}

@end
