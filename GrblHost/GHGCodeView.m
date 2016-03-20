//
//  GHGCodeView.m
//  GCodeViewer
//
//  Created by JRH on 20.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGCodeView.h"
#import "GHGCode.h"
#import "GHGCodeCommand.h"

@implementation GHGCodeView

@synthesize scale, visibleLayer, flipView;
@synthesize progressPoint, showProgressPoint;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        gcode = [[GHGCode alloc] init];
        lineColors = [[NSMutableArray alloc] init];
        transform = [[NSAffineTransform alloc] init];
        dragStart = dragged = NSMakePoint(0, 0);
        scale = 5;
        visibleLayer = 0;
        flipView = NO;
        gcodeLoaded = NO;
        showProgressPoint = NO;
        progressPoint = NSMakePoint(0, 0);
    }
    return self;
}

- (void)drawGCode:(GHGCode *)gc
{
    gcode = gc;
    dragStart = dragged = NSMakePoint(0, 0);
    gcodeLoaded = YES;
    visibleLayer = 0;
    
    if ([gcode maxWidth] > [gcode maxHeight]) {
        scale = floor(NSMaxX([self bounds])/([gcode maxWidth]*1.1));
    } else {
        scale = floor(NSMaxY([self bounds])/([gcode maxHeight]*1.1));
    }

    DLog(@"Max width: %f, Max height: %f", [gcode maxWidth], [gcode maxHeight]);
    DLog(@"Bounds width: %f, height: %f", NSMaxX([self bounds]), NSMaxY([self bounds]));
    
    biggestLayer = 0;
    int biggestLayerSize = 0;
    for (NSString *key in [[gcode layers] allKeys]) {
        NSDictionary *dict = [[gcode layers] objectForKey:key];
        NSArray *keys = [dict allKeys];
        int layerSize = [[dict objectForKey:[keys objectAtIndex:0]] intValue];
        if (layerSize > biggestLayerSize) {
            biggestLayerSize = layerSize;
            biggestLayer = [key intValue];
        }
        //DLog(@"Layer %@ with %i objects", key, layerSize);
    }
    DLog(@"Biggest layer: %i with %i", biggestLayer, biggestLayerSize);
    
    NSArray *colors = [NSArray arrayWithObjects:
                       [NSColor redColor],
                       [NSColor purpleColor],
                       [NSColor greenColor],
                       [NSColor blueColor],
                       [NSColor magentaColor],
                       [NSColor cyanColor],
                       [NSColor orangeColor],
                       //[NSColor yellowColor],
                       [NSColor grayColor],
                       [NSColor brownColor],
                       nil];

    int numLayers = (int)[[gcode layers] count];
    
    [lineColors removeAllObjects];
    
    int ci = 0;
    for (int i = 1; i <= numLayers; i++) {
        if (i == biggestLayer) {
            [lineColors addObject:[NSColor blackColor]];
        }
        else {
            if (ci >= [colors count]) {
                ci = 0;
            }
            [lineColors addObject:[colors objectAtIndex:ci]];
            ci++;
        }
    }
    
    DLog(@"Layers: %ld, Colors: %ld", [[gcode layers] count], [lineColors count]);
    //DLog(@"Layer array: %@", [gcode layers]);
    
}



- (NSColor *)layerColor:(int)layer
{
    if (layer > [lineColors count]) {
        return [NSColor blackColor];
    }
    return [lineColors objectAtIndex:layer-1];
}


- (NSBezierPath *)curvedLineTo:(NSPoint)end from:(NSPoint)start withOffset:(NSPoint)offset clockwise:(BOOL)cw
{
    NSPoint curveCenter = NSMakePoint(start.x+offset.x, start.y+offset.y);
    double radius = sqrt(pow(start.x-curveCenter.x, 2)+pow(start.y-curveCenter.y, 2));
 
    double startAngle;
    double endAngle;
    
    if (start.x == end.x && start.y == end.y) {
        startAngle = 0;
        endAngle = 360;
    }
    else {
        startAngle = atan2(end.y-curveCenter.y, end.x-curveCenter.x)*180/M_PI;
        endAngle = atan2(start.y-curveCenter.y, start.x-curveCenter.x)*180/M_PI;
    }

    //if (start.x != end.x && start.y != end.y) {
    //}

    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path appendBezierPathWithArcWithCenter:curveCenter radius:radius startAngle:startAngle endAngle:endAngle clockwise:cw];
    
#if (GHDEBUG >= 2)
    [path appendBezierPathWithRect:NSMakeRect(start.x-0.0075, start.y-0.0075, 0.015, 0.015)];
    [path appendBezierPathWithRect:NSMakeRect(end.x-0.0075, end.y-0.0075, 0.015, 0.015)];
    [path appendBezierPathWithRect:NSMakeRect(curveCenter.x-0.009, curveCenter.y-0.009, 0.018, 0.018)];
#endif
    
    return path;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:[self bounds]];

    [[NSColor blackColor] set];
    [NSBezierPath strokeRect:[self bounds]];
    
    double x = (self.bounds.size.width/2)-dragged.x;
    double y = (self.bounds.size.height/2)-(flipView ? -dragged.y : dragged.y);
    center = NSMakePoint(x, y);
    
    transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:center.x yBy:center.y];
    [transform scaleBy:(scale == 0 ? 0.01 : scale)];
    
    // Draw XY-line
    NSBezierPath *xyLine = [NSBezierPath bezierPath];
    [xyLine moveToPoint:NSMakePoint(NSMaxX([self bounds])*-200, 0)];
    [xyLine lineToPoint:NSMakePoint(NSMaxX([self bounds])*200, 0)];
    [xyLine moveToPoint:NSMakePoint(0, NSMaxY([self bounds])*-200)];
    [xyLine lineToPoint:NSMakePoint(0, NSMaxY([self bounds])*200)];
    [xyLine setLineWidth:0.1];
    [[NSColor blackColor] set];
    [xyLine transformUsingAffineTransform:transform];
    [xyLine stroke];

    
    NSPoint lastPoint = NSMakePoint(0, 0);
        
    NSArray *commands = [gcode commands];
    for (int i=0; i < [commands count]; i++) {
        
        GHGCodeCommand *cmd = [commands objectAtIndex:i];
        NSPoint point = NSMakePoint([cmd hasX]?[cmd X]:lastPoint.x, [cmd hasY]?[cmd Y]:lastPoint.y);

        if (![cmd hasX] && ![cmd hasY]) {
            continue;
        }
        
        if (visibleLayer != 0 && visibleLayer != [cmd layer]) {
            lastPoint = point;
            continue;
        }

        NSBezierPath* path = [NSBezierPath bezierPath];

        if ([cmd hasG] && ([cmd G] == 2 || [cmd G] == 3))
        {
            NSPoint offset = NSMakePoint([cmd hasI]?[cmd I]:0, [cmd hasJ]?[cmd J]:0);
            BOOL cw = ([cmd G] == 2 ? NO : YES);
            
            path = [self curvedLineTo:point from:lastPoint withOffset:offset clockwise:cw];
        }
        else {
            [path moveToPoint:lastPoint];
            [path lineToPoint:point];
        }        
        
        [[self layerColor:[cmd layer]] set];
        [path setLineWidth: 0.5+fabs(scale/500)];
        [path transformUsingAffineTransform:transform];
        [path stroke];
        
        lastPoint = point;
        
    }
    
    if (showProgressPoint) {
        double radius = 0.08;
        NSBezierPath *p = [NSBezierPath bezierPath];
        [p appendBezierPathWithArcWithCenter:progressPoint radius:radius startAngle:0 endAngle:360];
        [[NSColor blueColor] set];
        [p setLineWidth:2];
        [p transformUsingAffineTransform:transform];
        [p stroke];
        
        p = [NSBezierPath bezierPath];
        [p moveToPoint:NSMakePoint(progressPoint.x-radius, progressPoint.y)];
        [p lineToPoint:NSMakePoint(progressPoint.x+radius, progressPoint.y)];
        [p moveToPoint:NSMakePoint(progressPoint.x, progressPoint.y-radius)];
        [p lineToPoint:NSMakePoint(progressPoint.x, progressPoint.y+radius)];
        [p setLineWidth:1];
        [p transformUsingAffineTransform:transform];
        [p stroke];
    }

}

- (void)resetView
{
    dragStart = dragged = NSMakePoint(0, 0);
    if (gcodeLoaded) {
        [self drawGCode:gcode];
    }
    showProgressPoint = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint start = [theEvent locationInWindow];
    dragStart = NSMakePoint(start.x+dragged.x, start.y+dragged.y);
    //DLog(@"Start drag: %@", NSStringFromPoint(dragStart));
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint p = [theEvent locationInWindow];
    dragged.x = dragStart.x-p.x;
    dragged.y = dragStart.y-p.y;
    //DLog(@"mousedragged x: %f, y: %f", dragged.x, dragged.y);
    [self setNeedsDisplay:YES];
}


- (void)scrollWheel:(NSEvent*)event {
    //DLog(@"MouseWheel, %f", [theEvent scrollingDeltaY]);
    mouseLocation = [event locationInWindow];
    scale += [event scrollingDeltaY]/100;
    [self setNeedsDisplay:YES];
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL)isOpaqu
{
    return YES;
}

- (BOOL)isFlipped
{
    return flipView;
}

@end
