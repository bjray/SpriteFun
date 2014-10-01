//
//  SKEmitterNode+Extensions.m
//  SpaceRun
//
//  Created by B.J. Ray on 8/15/14.
//  Copyright (c) 2014 109Software. All rights reserved.
//

#import "SKEmitterNode+Extensions.h"

@implementation SKEmitterNode (Extensions)
+ (SKEmitterNode *)rcw_nodeWithFile:(NSString *)filename {
    NSString *baseName = [filename stringByDeletingPathExtension];
    NSString *extension = [filename pathExtension];
    if ([extension length] == 0) {
        extension = @"sks";
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:extension];
    SKEmitterNode *node = (id)[NSKeyedUnarchiver unarchiveObjectWithFile:path];
    return node;
}

- (void)rcw_dieOutInDuration:(NSTimeInterval)duration {
    SKAction *firstWait = [SKAction waitForDuration:duration];
    __weak SKEmitterNode *weakSelf = self;
    
    SKAction *stop = [SKAction runBlock:^{
        weakSelf.particleBirthRate = 0;
    }];
    
    SKAction *secondWait = [SKAction waitForDuration: self.particleLifetime];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *dieOut = [SKAction sequence:@[firstWait, stop, secondWait, remove]];
    [self runAction:dieOut];
}
@end
