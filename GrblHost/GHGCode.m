//
//  GHGCode.m
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGCode.h"
#import "GHGCodeCommand.h"

@implementation GHGCode

@synthesize commands;
@synthesize minX, maxX, minY, maxY, minZ, maxZ;
@synthesize layers;

- (id)init
{
    self = [super init];
    if (self) {
        commands = [[NSMutableArray alloc] init];
        minX = maxX = minY = maxY = minZ = maxZ = 0;
    }
    return self;
}

- (id)initWithCommand:(GHGCodeCommand *)cmd
{
    self = [super init];
    if (self) {
        commands = [[NSMutableArray alloc] init];
        [self addCommand:cmd];
    }
    return self;
}

- (void)addCommand:(GHGCodeCommand *)cmd
{
    minX = MIN([cmd X], minX); maxX = MAX([cmd X], maxX);
    minY = MIN([cmd Y], minY); maxY = MAX([cmd Y], maxY);
    minZ = MIN([cmd Z], minZ); maxZ = MAX([cmd Z], maxZ);
    
    [commands addObject:cmd];

    //DLog(@"Adding command, line: %ld", [commands count]);
}

- (double)maxWidth
{
    return fabs(minX) + fabs(maxX);
}

- (double)maxHeight
{
    return fabs(minY) + fabs(maxY);
}

- (double)maxDepth
{
    return fabs(minZ) + fabs(maxZ);
}

- (double)maxSize
{
    DLog(@"maxWidth %f, maxHeight %f", [self maxWidth], [self maxHeight]);
    return MAX([self maxWidth], [self maxHeight]);
}

- (unsigned long)lines
{
    return [commands count];
}

@end
