//
//  GHGcodeCommand.h
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GHGCodeCommand : NSObject
{
    double X, Y, Z, I, J, K, F;
    int G, T, layer;
    BOOL hasX, hasY, hasZ, hasG, hasI, hasJ, hasK, hasF, hasT, hasLayer;
        
    NSString *gcodeString;
    NSString *grblResponse;
}

@property (readonly) double X, Y, Z, I, J, K, F;
@property (readonly) int G, T;
@property (readonly) int layer;
@property (nonatomic) BOOL hasX, hasY, hasZ, hasG, hasI, hasJ, hasK, hasF, hasT, hasLayer;
@property NSString *gcodeString;
@property NSString *grblResponse;

- (void)setX:(double)val;
- (void)setY:(double)val;
- (void)setZ:(double)val;
- (void)setG:(int)val;
- (void)setI:(double)val;
- (void)setJ:(double)val;
- (void)setK:(double)val;
- (void)setF:(double)val;
- (void)setT:(int)val;
- (void)setLayer:(int)newLayer;

@end
