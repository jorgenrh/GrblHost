//
//  GHFileViewController.h
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHFile;
@class GHGrbl;

@interface GHFileViewController : NSViewController
{
    GHGrbl *grbl;
    GHFile *file;
    
    NSTimer *streamTimer;
    NSDate *streamingStart;
    
    IBOutlet NSTextField *filePathField;
    IBOutlet NSTextField *lineStatusField;
    IBOutlet NSTextField *commandField;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *percentageField;
    IBOutlet NSTextField *timerField;
    
    BOOL isStreaming;

}
//@property IBOutlet NSTextField *lineStatusField;
@property (nonatomic, retain) NSProgressIndicator *progressBar;

- (IBAction)browseFile:(id)sender;
- (IBAction)startStream:(id)sender;
- (IBAction)stopStream:(id)sender;
- (IBAction)pauseStream:(id)sender;


// Methods
- (void)fileProgress;
- (void)fileFinished;
- (void)updateTimer:(NSTimer *)timer;

// Notification methods
- (void)fileLoaded:(NSNotification *)notification;
- (void)grblRead:(NSNotification *)notification;

@end
