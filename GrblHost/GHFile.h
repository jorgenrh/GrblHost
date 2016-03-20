//
//  GHFile.h
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GHGrbl;
@class GHGCode;
@class GHGCodeCommand;

enum {
    kGHFileStreamingActive,
    kGHFileStreamingPaused,
    kGHFileStopStreamingAfterNextRead,
    kGHFileStreamingNotActive
};

extern NSString *const kGHFileGCodeLoaded;
extern NSString *const kGHFileProgressUpdate;

@interface GHFile : NSObject
{
    GHGrbl *grbl;
    GHGCode *gcode;
    GHGCodeCommand *currentCommand;
    long commandIndex;
    int streaming;
    BOOL fileLoaded;
    
    NSString *filePath;
    
    NSPoint currentPoint;
    
}

@property NSString *filePath;
@property long commandIndex;
@property (readonly) GHGCodeCommand *currentCommand;
@property GHGCode *gcode;
@property (readonly) NSPoint currentPoint;


+ (GHFile *)sharedInstance;


// Methods
- (BOOL)loadFile:(NSURL *)fileUrl;
- (long)lines;
- (BOOL)isActive;
- (BOOL)isPaused;


// Streaming methods
- (BOOL)startStreaming;
- (void)stopStreaming;
- (BOOL)pauseStreaming;
- (void)sendNextCommand:(NSString *)response;


// Notification methods
- (void)grblReadLine:(NSNotification *)notification;

@end
