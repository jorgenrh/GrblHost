//
//  GHGCode.h
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GHGCodeCommand;

@interface GHGCode : NSObject
{
    NSMutableArray *commands;
    double minX, maxX, minY, maxY, minZ, maxZ;
    NSDictionary *layers;
}

@property NSMutableArray *commands;
@property double minX, maxX, minY, maxY, minZ, maxZ;
@property NSDictionary *layers;

- (void)addCommand:(GHGCodeCommand *)cmd;
- (double)maxWidth;
- (double)maxHeight;
- (double)maxSize;
- (double)maxDepth;

- (unsigned long)lines;

@end
