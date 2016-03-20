//
//  GHGrblSettingsWindowController.h
//  GrblHost
//
//  Created by JRH on 29.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHGrbl;

@interface GHGrblSettingsWindowController : NSWindowController <NSWindowDelegate, NSTableViewDataSource>
{
    GHGrbl *grbl;
    
    IBOutlet NSTableView *settingsTable;
    
    IBOutlet NSProgressIndicator *progressIndicator;
}


- (IBAction)refreshSettings:(id)sender;

- (void)requestSettings;
- (void)saveSetting:(NSString *)setting;

// Notifications
- (void)grblReadLine:(NSNotification *)notification;
- (void)grblConnected:(NSNotification *)notification;


@end
