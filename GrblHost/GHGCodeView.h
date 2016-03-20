//
//  GHGCodeView.h
//  GCodeViewer
//
//  Created by JRH on 20.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHGCode;
@class GHGCodeCommand;

@interface GHGCodeView : NSView
{
    GHGCode *gcode;
    float scale;
    
    NSAffineTransform* transform;
    NSPoint center;

    NSPoint dragStart;
    NSPoint dragged;
    NSPoint mouseLocation;
    
    int biggestLayer;
    NSMutableArray *lineColors;
    
    int visibleLayer;
    BOOL flipView;
    BOOL gcodeLoaded;
    
    NSPoint progressPoint;
    BOOL showProgressPoint;
}

@property float scale;
@property int visibleLayer;
@property BOOL flipView;
@property NSPoint progressPoint;
@property BOOL showProgressPoint;


- (void)drawGCode:(GHGCode *)gc;
- (NSColor *)layerColor:(int)layer;
- (void)resetView;


- (NSBezierPath *)curvedLineTo:(NSPoint)start from:(NSPoint)end withOffset:(NSPoint)offset clockwise:(BOOL)cw;

@end
