//
//  GHFileViewController.m
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHFileViewController.h"
#import "GHAppDelegate.h"
#import "GHFile.h"
#import "GHGrbl.h"
#import "GHGCodeCommand.h"

@implementation GHFileViewController

@synthesize progressBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isStreaming = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    grbl = [GHGrbl sharedInstance];
    file = [GHFile sharedInstance];
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileLoaded:) name:kGHFileGCodeLoaded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grblRead:) name:kGHGrblRead object:nil];
    
    [self resetUI];
}

#pragma mark - IBActions

- (void)browseFile:(id)sender
{
    NSOpenPanel* openFile = [NSOpenPanel openPanel];
    [openFile setAllowsMultipleSelection:NO];
    //[openFile setAllowedFileTypes:[NSArray arrayWithObjects:@"gcode", @"nc", @"txt", nil]];
    
    if (![openFile runModal]) {
        return;
    }
    
    NSURL *fileUrl = [[openFile URLs] lastObject];

    if ([file loadFile:fileUrl]) {
        DLog(@"File loaded");
        [filePathField setStringValue:[fileUrl path]];
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:fileUrl];
    }
}

- (void)startStream:(id)sender
{
    if ([file startStreaming]) {
        streamingStart = [NSDate date];
        streamTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
        isStreaming = YES;
    }
    
}

- (void)stopStream:(id)sender
{
    if (isStreaming) {
        [self resetUI];
        [commandField setStringValue:@"Stopped"];
    }
}

- (void)pauseStream:(id)sender
{
    if ([file pauseStreaming]) {
        [commandField setStringValue:([file isPaused] ? @"Paused" : @"...")];
    }
}

- (void)resetUI
{
    [file stopStreaming];
    isStreaming = NO;
    [lineStatusField setStringValue:[NSString stringWithFormat:@"Line: 0/%ld", [file lines]]];
    [commandField setStringValue:@"..."];
    [percentageField setStringValue:@"0%"];
    [streamTimer invalidate];
    streamTimer = nil;
    [timerField setStringValue:@"Time: 00:00:00"];
    [progressBar setDoubleValue:0];
    isStreaming = NO;
}

- (void)updateTimer:(NSTimer *)timer
{
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:streamingStart];
    int hour = (long)duration / (60*60);
    int min = (long)duration / 60;
    int sec = (long)duration % 60;
    [timerField setStringValue:[NSString stringWithFormat:@"Time: %02d:%02d:%02d", hour, min, sec]];
}


- (void)fileProgress
{
    //[progressBar incrementBy:1.0];
    [progressBar displayIfNeeded];

    unsigned long line = [file commandIndex]+1;
    [commandField setStringValue:[[file currentCommand] gcodeString]];
    [lineStatusField setStringValue:[NSString stringWithFormat:@"Line: %ld/%ld", line, [file lines]]];
    
    double percentage = (double)line/(double)[file lines]*100.0;
    [percentageField setStringValue:[NSString stringWithFormat:@"%.0f%%", percentage]];

    [progressBar setDoubleValue:percentage];

    
    if (line == [file lines]) {
        [self fileFinished];
    }
}

- (void)fileFinished
{
    [progressBar stopAnimation:self];
    [commandField setStringValue:@"Finished!"];
    [streamTimer invalidate];
    streamTimer = nil;
}

#pragma mark - Notifications

- (void)grblRead:(NSNotification *)notification
{
    if ([file isActive]) {
        [self fileProgress];
    }
}

- (void)fileLoaded:(NSNotification *)notification
{
    [filePathField setStringValue:[file filePath]];
    [self resetUI];
}


@end
