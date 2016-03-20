//
//  GHControlsViewController.m
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHControlsViewController.h"
#import "GHAppDelegate.h"
#import "GHGrbl.h"

@interface GHControlsViewController ()

@end

@implementation GHControlsViewController

@synthesize Xcoord, Ycoord, Zcoord;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    grbl = [GHGrbl sharedInstance];
    [flipXYAxisCheckBox setState:[app->defaults boolForKey:@"ControlsFlipXYAxis"]];
    [stepSizeField setStringValue:[app->defaults stringForKey:@"ControlsStepSize"]];
    
    /*
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:0];
    [formatter setMaximumFractionDigits:4];
    [formatter setAllowsFloats:YES];
    [[stepSizeField cell] setFormatter:formatter];
    */
}


#pragma mark - IBActions

- (void)saveCheckBoxState:(id)sender
{
    [app->defaults setBool:[sender state] forKey:@"ControlsFlipXYAxis"];
}

- (void)goHome:(id)sender
{
    [grbl goHome];
}

- (void)setHome:(id)sender
{
    Xcoord = Ycoord = Zcoord = 0;
    [grbl setHome];
}

- (void)adjustAxis:(id)sender
{
    double step = [stepSizeField doubleValue];
    if (step == 0) {
        [stepSizeField setStringValue:@"1"];
        step = 1;
    }
    
    [app->defaults setObject:[NSString stringWithFormat:@"%.4f", step] forKey:@"ControlsStepSize"];
    
    Xcoord = [grbl X];
    Ycoord = [grbl Y];
    Zcoord = [grbl Z];
    
    BOOL flipped = [flipXYAxisCheckBox state];
    double coord;
    
    NSString *button = [sender identifier];
    NSMutableString *command = [[NSMutableString alloc] initWithString:@"G01 "];
    
    if ([button isEqualToString:@"up"]) {
        coord = (flipped ? Xcoord : Ycoord) + step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
    }
    else if ([button isEqualToString:@"down"]) {
        coord = (flipped ? Xcoord : Ycoord) - step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
    }
    else if ([button isEqualToString:@"left"]) {
        coord = (flipped ? Ycoord : Xcoord) - step;
        [command appendFormat:@"%@%f", (flipped ? @"Y" : @"X"), coord];
    }
    else if ([button isEqualToString:@"right"]) {
        coord = (flipped ? Ycoord : Xcoord) + step;
        [command appendFormat:@"%@%f", (flipped ? @"Y" : @"X"), coord];
    }
    else if ([button isEqualToString:@"zUp"]) {
        Zcoord += step;
        [command appendFormat:@"Z%f", Zcoord];
    }
    else if ([button isEqualToString:@"zDown"]) {
        Zcoord -= step;
        [command appendFormat:@"Z%f", Zcoord];
    }
    // TODO: Correct flipping
    else if ([button isEqualToString:@"upLeft"]) {
        coord = (flipped ? Xcoord : Ycoord) + step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
        coord = (flipped ? Ycoord : Xcoord) - step;
        [command appendFormat:@" %@%f", (flipped ? @"Y" : @"X"), coord];
    }
    else if ([button isEqualToString:@"upRight"]) {
        coord = (flipped ? Xcoord : Ycoord) + step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
        coord = (flipped ? Ycoord : Xcoord) + step;
        [command appendFormat:@" %@%f", (flipped ? @"Y" : @"X"), coord];
    }
    else if ([button isEqualToString:@"downLeft"]) {
        coord = (flipped ? Xcoord : Ycoord) - step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
        coord = (flipped ? Ycoord : Xcoord) - step;
        [command appendFormat:@" %@%f", (flipped ? @"Y" : @"X"), coord];
    }
    else if ([button isEqualToString:@"downRight"]) {
        coord = (flipped ? Xcoord : Ycoord) - step;
        [command appendFormat:@"%@%f", (flipped ? @"X" : @"Y"), coord];
        coord = (flipped ? Ycoord : Xcoord) + step;
        [command appendFormat:@" %@%f", (flipped ? @"Y" : @"X"), coord];
    }
    
    //DLog(@"Identifier %@, Command: %@", button, command);
    [grbl send:command withFlag:kGHGrblFileCommand];
}

- (void)stepFieldDidChange:(id)sender
{
    // TODO: Custom number formatter, to allow both .,
    DLog(@"Field edited!");
}

@end
