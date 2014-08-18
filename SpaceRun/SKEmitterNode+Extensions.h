//
//  SKEmitterNode+Extensions.h
//  SpaceRun
//
//  Created by B.J. Ray on 8/15/14.
//  Copyright (c) 2014 109Software. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKEmitterNode (Extensions)
+ (SKEmitterNode *)rcw_nodeWithFile:(NSString *)filename;
- (void)rcw_dieOutInDuration:(NSTimeInterval)duration;
@end
