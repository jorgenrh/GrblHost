//
//  GHCommandViewController.h
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHGrbl;

@interface GHCommandViewController : NSViewController
{
    GHGrbl *grbl;
    
    IBOutlet NSTextField *inputField;
}

- (IBAction)sendCommand:(id)sender;
- (IBAction)setHome:(id)sender;
- (IBAction)goHome:(id)sender;

- (IBAction)specialCommand:(id)sender;

@end
