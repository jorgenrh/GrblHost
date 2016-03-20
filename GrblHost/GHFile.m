//
//  GHFile.m
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHFile.h"
#import "GHGrbl.h"
#import "GHGCode.h"
#import "GHGCodeCommand.h"
#import "GHGCodeImport.h"


NSString *const kGHFileGCodeLoaded = @"kGHFileGCodeLoaded";
NSString *const kGHFileProgressUpdate = @"kGHFileProgressUpdate";


@implementation GHFile

@synthesize filePath;
@synthesize commandIndex;
@synthesize currentCommand;
@synthesize gcode;
@synthesize currentPoint;

+ (GHFile *)sharedInstance {
    static GHFile *instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        grbl = [GHGrbl sharedInstance];
        streaming = kGHFileStreamingNotActive;
        
        currentPoint = NSMakePoint(0, 0);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grblReadLine:) name:kGHGrblReadLine object:nil];
    }
    return self;
}



#pragma mark - Methods

- (BOOL)loadFile:(NSURL *)fileUrl
{
    GHGCodeImport *importer = [[GHGCodeImport alloc] initWithFile:[fileUrl path]];
    gcode = [importer analyzeGcode];
    
    DLog(@"trying to load %@", [fileUrl path]);
    
    if ([gcode lines] > 0) {
        DLog(@"Lines: %ld", [gcode.commands count]);
        DLog(@"Max Width: %f Height: %f Depth: %f", [gcode maxWidth], [gcode maxHeight], [gcode maxDepth]);
        
        DLog(@"maxX: %f, minX: %f, maxY: %f, minY: %f, maxZ: %f, minZ: %f", [gcode maxX], [gcode minX], [gcode maxY], [gcode minY], [gcode maxZ], [gcode minZ]);
        
        [self setFilePath:[fileUrl path]];
        //DLog(@"fabs(minY) %f", fabs([gcode minY]));
        [[NSNotificationCenter defaultCenter] postNotificationName:kGHFileGCodeLoaded object:nil];
        fileLoaded = YES;
    }
    else {
        gcode = nil;
        fileLoaded = NO;
    }

    return fileLoaded;
}

- (long)lines
{
    return [gcode lines];
}

- (BOOL)isActive
{
    return (streaming == kGHFileStreamingActive);
}

- (BOOL)isPaused
{
    return (streaming == kGHFileStreamingPaused);
}


#pragma mark - Streaming methods

- (BOOL)startStreaming
{
    if (![grbl isConnected] || !fileLoaded) {
        return NO;
    }

    commandIndex = 0;
    streaming = kGHFileStreamingActive;
    currentCommand = [[gcode commands] objectAtIndex:commandIndex];
    [grbl sendCommand:currentCommand withFlag:kGHGrblFileCommand];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kGHFileProgressUpdate object:nil];
    return YES;
}

- (void)stopStreaming
{
    commandIndex = 0;
    streaming = kGHFileStreamingNotActive;
}

- (BOOL)pauseStreaming
{
    if ([grbl isConnected]) {
        if (streaming != kGHFileStreamingPaused) {
            streaming = kGHFileStreamingPaused;
        }
        else {
            streaming = kGHFileStreamingActive;
            [self sendNextCommand:nil];
        }
        return YES;
    }
    return NO;
}


- (void)sendNextCommand:(NSString *)response
{
    if (response != nil) {
        [[[gcode commands] objectAtIndex:commandIndex] setGrblResponse:response];
    }

    if (streaming == kGHFileStreamingPaused) {
        return;
    }
    
    if (commandIndex < [gcode lines]-1) {
        
        if (streaming == kGHFileStreamingActive) {
        
            commandIndex++;
            currentCommand = [[gcode commands] objectAtIndex:commandIndex];
            
            currentPoint.x = [currentCommand hasX] ? [currentCommand X] : currentPoint.x;
            currentPoint.y = [currentCommand hasY] ? [currentCommand Y] : currentPoint.y;
            
            //[grbl setMode:kGHGrblStreamCommandSent];
            [grbl sendCommand:currentCommand withFlag:kGHGrblFileCommand];
            
        }

    }
    else {
        streaming = kGHFileStreamingNotActive;
    }
    
}



#pragma mark - Notification methods

- (void)grblReadLine:(NSNotification *)notification
{
    if (streaming == kGHFileStreamingActive) {
        NSString *response = (NSString *)[notification object];
        [self sendNextCommand:response];
    }
}



@end
