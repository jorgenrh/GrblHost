//
//  GHControlsViewController.h
//  GrblHost
//
//  Created by JRH on 26.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHGrbl;

@interface GHControlsViewController : NSViewController
{
    GHGrbl *grbl;
    
    IBOutlet NSButton *flipXYAxisCheckBox;
    IBOutlet NSTextField *stepSizeField;
    
    double Xcoord, Ycoord, Zcoord;
}
@property double Xcoord, Ycoord, Zcoord;

- (IBAction)saveCheckBoxState:(id)sender;

- (IBAction)adjustAxis:(id)sender;

- (IBAction)setHome:(id)sender;
- (IBAction)goHome:(id)sender;

- (IBAction)stepFieldDidChange:(id)sender;
@end
