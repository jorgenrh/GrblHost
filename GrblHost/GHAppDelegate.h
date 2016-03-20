//
//  GHAppDelegate.h
//  GrblHost
//
//  Created by JRH on 16.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GHGrbl;
@class GHGCode;
@class GHFile;
@class GHGCodeView;
@class GHCommandViewController;
@class GHFileViewController;
@class GHControlsViewController;

@interface GHAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource>
{
    GHGrbl *grbl;
    GHFile *file;
    GHGCode *fileGCode;
    
    IBOutlet GHGCodeView *gcodeView;
    IBOutlet NSPopUpButton *gcodeLayerSelection;
    
    IBOutlet NSPopUpButton *serialPortMenu;
    IBOutlet NSPopUpButton *baudRateMenu;
    
    IBOutlet NSToolbarItem *toggleConnectButton;
    IBOutlet NSTextField *statusBarField;
    
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSButton *autoScrollCheckBox;
    IBOutlet NSButton *flipViewCheckBox;
    
    IBOutlet NSTextField *gcodeUIDataX;
    IBOutlet NSTextField *gcodeUIDataY;
    IBOutlet NSTextField *gcodeUIDataZ;
    IBOutlet NSTextField *gcodeUIDataFeedrate;
    IBOutlet NSTextField *gcodeUIDataTool;
    IBOutlet NSTextField *gcodeUIDataLayer;

    
    NSWindowController *grblSettingsWindowController;
    NSWindowController *preferencesWindowController;
    
@public
    IBOutlet NSTableView *historyTable;
    IBOutlet NSTabView *tabView;
    NSUserDefaults *defaults;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet GHCommandViewController *commandViewController;
@property (assign) IBOutlet GHFileViewController *fileViewController;
@property (assign) IBOutlet GHControlsViewController *controlsViewController;
@property (readwrite) NSUserDefaults *defaults;


// Methods
- (void)statusOutput:(NSString *)output;
- (void)statusOutput:(NSString *)output boldFont:(BOOL)bold;
- (void)statusOutput:(NSString *)output attribute:(NSDictionary *)attr;
- (void)updateGCodeUIData;


// IBActions
- (IBAction)toggleConnect:(id)sender;
- (IBAction)stopEverything:(id)sender;
- (IBAction)browseFile:(id)sender;
- (IBAction)saveCheckBoxState:(id)sender;

- (IBAction)flipGCodeView:(id)sender;
- (IBAction)resetGCodeView:(id)sender;
- (IBAction)selectGCodeLayer:(id)sender;
- (IBAction)openGrblSettings:(id)sender;

- (IBAction)openPreferences:(id)sender;
- (IBAction)clearOutput:(id)sender;

// Notifications
- (void)grblRead:(NSNotification *)notification;
- (void)grblReadLine:(NSNotification *)notification;
- (void)grblPortListUpdated:(NSNotification *)notification;
- (void)grblConnected:(NSNotification *)notification;
- (void)grblDisconnected:(NSNotification *)notification;
- (void)fileLoaded:(NSNotification *)notification;

@end

GHAppDelegate *app; // Not good, but it works
