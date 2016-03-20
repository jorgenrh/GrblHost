//
//  GHGcodeCommand.m
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGCodeCommand.h"

@implementation GHGCodeCommand

@synthesize X, Y, Z, I, J, K, F;
@synthesize G, T;
@synthesize layer;
@synthesize hasX, hasY, hasZ, hasG, hasI, hasJ, hasK, hasF, hasT, hasLayer;
@synthesize gcodeString, grblResponse;

- (id)init
{
    self = [super init];
    if (self) {
        X = Y = Z = I = J = K = F = 0.0;
        G = T = 0;
        hasLayer = NO;
    }
    return self;
}

- (void)setX:(double)val
{
    hasX = YES;
    X = val;
}

- (void)setY:(double)val
{
    hasY = YES;
    Y = val;
}
- (void)setZ:(double)val
{
    hasZ = YES;
    Z = val;
}
- (void)setG:(int)val
{
    hasG = YES;
    G = val;
}
- (void)setI:(double)val
{
    hasI = YES;
    I = val;
}
- (void)setJ:(double)val
{
    hasJ = YES;
    J = val;
}
- (void)setK:(double)val
{
    hasK = YES;
    K = val;
}
- (void)setF:(double)val
{
    hasF = YES;
    F = val;
}
- (void)setT:(int)val
{
    hasT = YES;
    T = val;
}

- (void)setLayer:(int)newLayer
{
    hasLayer = YES;
    layer = newLayer;
}

@end
