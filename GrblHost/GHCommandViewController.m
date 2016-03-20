//
//  GHCommandViewController.m
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHCommandViewController.h"
#import "GHAppDelegate.h"
#import "GHGrbl.h"

@interface GHCommandViewController ()

@end

@implementation GHCommandViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        grbl = [GHGrbl sharedInstance];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        grbl = [GHGrbl sharedInstance];
    }
    return self;
}

- (void)awakeFromNib
{
    grbl = [GHGrbl sharedInstance];
    [inputField setTarget:self];
    [inputField setAction:@selector(sendCommand:)];
}

- (void)sendCommand:(id)sender
{
    if ([app->tabView indexOfTabViewItem:[app->tabView selectedTabViewItem]] != 0) {
        return;
    }

    if ([grbl isConnected]) {
        NSString *string = [inputField stringValue];
        if ([string length] > 0) {
            DLog(@"Sending command: %@", string);
            [inputField setStringValue:@""];

            if ([grbl send:string withFlag:kGHGrblNone]) {
                DLog(@"sent");
            } else {
                DLog(@"error sending");
            }
        }
    }
    else {
        DLog(@"Not connected");
    }
}

- (void)goHome:(id)sender
{
    [grbl goHome];
}

- (void)setHome:(id)sender
{
    [grbl setHome];
}

- (void)specialCommand:(id)sender
{
    NSString *title = [sender identifier];
    NSString *command;
    
    if ([title isEqualToString:@"statusReport"]) {
        command = @"?";
    }
    else if ([title isEqualToString:@"feedHold"]) {
        command = @"!";
    }
    else if ([title isEqualToString:@"cycleStart"]) {
        command = @"~";
    }
    else if ([title isEqualToString:@"reset"]) {
        command = [NSString stringWithFormat:@"%c", (char)0x18]; // ctrl-x
    }
    
    DLog(@"Sending %@", command);
    if ([command length] > 0) {
        if ([title isEqualToString:@"reset"]) {
            [grbl reset];
        }
        else {
            [grbl send:command];
        }
    }
}


@end
