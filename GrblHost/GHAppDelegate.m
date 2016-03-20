//
//  GHAppDelegate.m
//  GrblHost
//
//  Created by JRH on 16.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHAppDelegate.h"
#import "AMSerialPort.h"
#import "GHGrbl.h"
#import "GHFile.h"

#import "GHGCode.h"
#import "GHGCodeImport.h"
#import "GHGCodeCommand.h"
#import "GHGCodeView.h"

#import "GHCommandViewController.h"
#import "GHFileViewController.h"
#import "GHControlsViewController.h"
#import "GHGrblSettingsWindowController.h"

#import "MASPreferencesWindowController.h"
#import "GHGeneralPreferencesViewController.h"
#import "GHGrblPreferencesViewController.h"

@implementation GHAppDelegate

@synthesize commandViewController, fileViewController, controlsViewController;
@synthesize defaults;

- (id)init
{
    self = [super init];
    if (self) {
        grbl = [GHGrbl sharedInstance];
        file = [GHFile sharedInstance];
        
        defaults = [NSUserDefaults standardUserDefaults];
        NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"GHDefaults" ofType:@"plist"];
        NSDictionary *defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
        [defaults registerDefaults:defaultsDict];

        
        NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
        [notification addObserver:self selector:@selector(grblRead:) name:kGHGrblRead object:nil];
        [notification addObserver:self selector:@selector(grblReadLine:) name:kGHGrblReadLine object:nil];
        [notification addObserver:self selector:@selector(grblPortListUpdated:) name:kGHGrblPortListUpdated object:nil];
        [notification addObserver:self selector:@selector(grblConnected:) name:kGHGrblConnected object:nil];
        [notification addObserver:self selector:@selector(grblDisconnected:) name:kGHGrblDisconnected object:nil];
        [notification addObserver:self selector:@selector(fileLoaded:) name:kGHFileGCodeLoaded object:nil];
        
        app = self;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [serialPortMenu removeAllItems];
    [serialPortMenu addItemsWithTitles:[grbl deviceNames]];
    [serialPortMenu selectItemAtIndex:[serialPortMenu numberOfItems]-1];
    NSString *defaultPort = [defaults stringForKey:@"SerialPortName"];
    if ([[serialPortMenu itemTitles] containsObject:defaultPort]) {
        [serialPortMenu selectItemWithTitle:defaultPort];
    }
    
    [baudRateMenu removeAllItems];
    [baudRateMenu addItemsWithTitles:[grbl baudRates]];
    [baudRateMenu selectItemWithTitle:@"57600"];
    NSString *defaultBaudRate = [defaults stringForKey:@"SerialBaudRate"];
    if ([[baudRateMenu itemTitles] containsObject:defaultPort]) {
        [baudRateMenu selectItemWithTitle:defaultBaudRate];
    }
    
    [autoScrollCheckBox setState:[defaults boolForKey:[autoScrollCheckBox title]]];
    [flipViewCheckBox setState:[defaults boolForKey:[flipViewCheckBox title]]];
    [gcodeView setFlipView:(BOOL)[flipViewCheckBox state]];
    
    NSTabViewItem *item;
    item = [tabView tabViewItemAtIndex:0];
    [item setView:[commandViewController view]];
    item = [tabView tabViewItemAtIndex:1];
    [item setView:[fileViewController view]];
    item = [tabView tabViewItemAtIndex:2];
    [item setView:[controlsViewController view]];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    //[grbl stop];
    [grbl disconnect];
    return NSTerminateNow;
}

- (BOOL)windowShouldClose:(id)sender
{
    if ([defaults boolForKey:@"ConfirmQuit"]) {
        if ([defaults boolForKey:@"ConfirmQuitIfConnected"]) {
            if ([grbl isConnected]) {
                return (NSRunAlertPanel(nil, @"You are still connected.\nQuit GrblHost?", @"OK", @"Cancel", nil) == NSAlertDefaultReturn);
            }
        }
        else {
            return (NSRunAlertPanel(nil, @"Quit GrblHost?", @"OK", @"Cancel", nil) == NSAlertDefaultReturn);
        }
    }
    [preferencesWindowController close];
    [grblSettingsWindowController close];
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if ([file loadFile:[NSURL fileURLWithPath:filename]]) {
        return YES;
    }
    return NO;
}



- (void)awakeFromNib {
    // build table header context menu
    NSArray *cols = [defaults arrayForKey:@"kGHGrblColumnsUserDefault"];
    
    NSMenu *tableHeaderContextMenu = [[NSMenu alloc] initWithTitle:@""];
    [[historyTable headerView] setMenu:tableHeaderContextMenu];
    NSArray *tableColumns = [NSArray arrayWithArray:[historyTable tableColumns]]; // clone array so compiles/runs on 10.5
    NSEnumerator *enumerator = [tableColumns objectEnumerator];
    NSTableColumn *column;
    while((column = [enumerator nextObject])) {
        NSString *title = [[column headerCell] title];
        NSMenuItem *item = [tableHeaderContextMenu addItemWithTitle:title action:@selector(contextMenuSelected:) keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:column];
        [item setState:cols?NSOffState:NSOnState];
        if(cols) [historyTable removeTableColumn:column]; // initially want to show all columns
    }
    // add columns in correct order with correct width, ensure menu items are in correct state
    enumerator = [cols objectEnumerator];
    NSDictionary *colinfo;
    while((colinfo = [enumerator nextObject])) {
        NSMenuItem *item = [tableHeaderContextMenu itemWithTitle:[colinfo objectForKey:@"title"]];
        if(!item) continue; // missing title
        [item setState:NSOnState];
        column = [item representedObject];
        [column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
        [historyTable addTableColumn:column];
    }
    [historyTable sizeLastColumnToFit];
}

- (void)contextMenuSelected:(id)sender {
    BOOL on = ([sender state] == NSOnState);
    [sender setState:on ? NSOffState : NSOnState];
    NSTableColumn *column = [sender representedObject];
    if(on) {
        [historyTable removeTableColumn:column];
        [historyTable sizeLastColumnToFit];
    } else {
        [historyTable addTableColumn:column];
        [historyTable sizeToFit];
    }
    [historyTable setNeedsDisplay:YES];
}





#pragma mark - Methods

- (void)statusOutput:(NSString *)output
{
    NSDictionary *font = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
    [self statusOutput:output attribute:font];
}
- (void)statusOutput:(NSString *)output boldFont:(BOOL)bold
{
    NSDictionary *boldFont = [NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:11.0] forKey:NSFontAttributeName];
    [self statusOutput:output attribute:boldFont];
}
- (void)statusOutput:(NSString *)output attribute:(NSDictionary *)attr
{
    NSAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:output attributes:attr];
    
    NSTextStorage *textStorage = [outputTextView textStorage];
	[textStorage beginEditing];
	[textStorage appendAttributedString:attrString];
	[textStorage endEditing];
	
	// scroll to the bottom
    if ([autoScrollCheckBox state] == NSOnState) {
        NSRange myRange;
        myRange.length = 1;
        myRange.location = [textStorage length];
        [outputTextView scrollRangeToVisible:myRange];
    }
}

- (void)updateGCodeUIData
{
    [gcodeUIDataX setStringValue:[NSString stringWithFormat:@"%f", [grbl X]]];
    [gcodeUIDataY setStringValue:[NSString stringWithFormat:@"%f", [grbl Y]]];
    [gcodeUIDataZ setStringValue:[NSString stringWithFormat:@"%f", [grbl Z]]];
    [gcodeUIDataFeedrate setStringValue:[NSString stringWithFormat:@"%i", [grbl feedRate]]];
    [gcodeUIDataTool setStringValue:[NSString stringWithFormat:@"%i", [grbl tool]]];
    [gcodeUIDataLayer setStringValue:[NSString stringWithFormat:@"%i", [grbl layer]]];
}


#pragma mark - IBAction methods

- (void)toggleConnect:(id)sender
{
    if (![grbl isConnected]) {
        DLog(@"trying to connect");
        if ([grbl connectTo:[serialPortMenu titleOfSelectedItem] withBaudRate:[[baudRateMenu titleOfSelectedItem] longLongValue]])
        {
            [toggleConnectButton setImage:[NSImage imageNamed:@"disconnect.png"]];
            [toggleConnectButton setLabel:@"Disconnect"];
        }
    }
    else {
        [grbl disconnect];
        [grbl connectTo:@"dummy" withBaudRate:0];
        [toggleConnectButton setImage:[NSImage imageNamed:@"connect.png"]];
        [toggleConnectButton setLabel:@"Connect"];
        [statusBarField setStringValue:@"Not connected"];
    }
    DLog(@"toggle connect %@", ([grbl isConnected] ? @"YES" : @"NO"));
}

- (void)stopEverything:(id)sender
{
    if ([file isActive]) {
        [fileViewController stopStream:self];
    }

    [grbl stop];
    DLog(@"Stop everything");
}

- (void)browseFile:(id)sender
{
    [tabView selectTabViewItemAtIndex:1];
    [[self fileViewController] browseFile:sender];
}

- (void)flipGCodeView:(id)sender
{
    [gcodeView setFlipView:(BOOL)[sender state]];
    [gcodeView setNeedsDisplay:YES];
    [self saveCheckBoxState:sender];
}

- (void)resetGCodeView:(id)sender
{
    [gcodeLayerSelection selectItemAtIndex:0];
    [gcodeView setVisibleLayer:0];
    [gcodeView resetView];
}

- (void)selectGCodeLayer:(id)sender
{
    int layer = (int)[gcodeLayerSelection indexOfSelectedItem];
    [gcodeView setVisibleLayer:layer];
    [gcodeView setNeedsDisplay:YES];
}

- (void)saveCheckBoxState:(id)sender
{
    [defaults setBool:[sender state] forKey:[sender title]];
}

- (void)openGrblSettings:(id)sender
{
    if (!grblSettingsWindowController) {
        grblSettingsWindowController = [[GHGrblSettingsWindowController alloc] initWithWindowNibName:@"GHGrblSettingsWindowController"];
    }
    [grblSettingsWindowController showWindow:nil];
}

- (void)clearOutput:(id)sender
{
    if ([[sender identifier] isEqualToString:@"table"]) {
        [grbl clearHistory];
        [historyTable reloadData];
    }
    else if ([[sender identifier] isEqualToString:@"textView"]) {
        [outputTextView setString:@""];
    }
}


- (void)openPreferences:(id)sender
{
    if (!preferencesWindowController) {
        NSViewController *generalViewController = [[GHGeneralPreferencesViewController alloc] init];
        //NSViewController *grblViewController = [[GHGrblPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, nil];
        NSString *title = @"Preferences";
        preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    [preferencesWindowController showWindow:nil];
}

#pragma mark - Command Table Methods


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[grbl commandHistory] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *dict = [[grbl commandHistory] objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    /*
    if ([identifier isEqualToString:@"command"]) {
        return [[dict valueForKey:identifier] gcodeString];
    }
     */
    if ([identifier isEqualToString:@"time"]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"[HH:mm:ss]"];
        return [formatter stringFromDate:[dict valueForKey:@"time"]];
    }
    if ([identifier isEqualToString:@"delay"]) {
        double delay = [[dict valueForKey:@"delay"] doubleValue] * 1000.0;
        if (delay != 0) {
            return [NSString stringWithFormat:@"%.0f ms", delay];
        }
        return @"...";
    }
    
    return [dict valueForKey:identifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    /*
     NSDictionary *dict = [[grbl grblSettings] objectAtIndex:row];
     NSString *identifier = [tableColumn identifier];
     [dict setValue:object forKey:identifier];
     DLog(@"Object edited");
     
     NSString *command = [NSString stringWithFormat:@"$%@=%@", [dict valueForKey:@"number"], object];
     [grbl send:command];
     */
}




#pragma mark - Notifications methods

- (void)grblRead:(NSNotification *)notification
{
    if ([file isActive]) {
        [gcodeView setProgressPoint:[file currentPoint]];
        [gcodeView setShowProgressPoint:YES];
        [gcodeView setNeedsDisplay:YES];
    }

    [historyTable reloadData];
    if ([autoScrollCheckBox state] == NSOnState) {
        [historyTable scrollToEndOfDocument:self];
    }
}

- (void)grblReadLine:(NSNotification *)notification
{
    if (!([grbl flag] & kGHGrblSilent) && !([grbl flag] & kGHGrblFileCommand)) {
        [self statusOutput:(NSString *)[notification object]];
    }
    
    [self updateGCodeUIData];
}

- (void)grblPortListUpdated:(NSNotification *)notification
{
    NSArray *ports = (NSArray *)[notification object];
    for (NSString *portName in ports) {
        [serialPortMenu addItemWithTitle:portName];
    }
}

- (void)grblDisconnected:(NSNotification *)notification
{
    [statusBarField setStringValue:@"Not Connected"];
    [self statusOutput:[NSString stringWithFormat:@"Disconnected from \"%@\"\n\n", [grbl currentPort]] boldFont:YES];
    [historyTable reloadData];
}

- (void)grblConnected:(NSNotification *)notification
{
    [self statusOutput:[NSString stringWithFormat:@"Connected to \"%@\"\n\n", [grbl currentPort]] boldFont:YES];
    [statusBarField setStringValue:[NSString stringWithFormat:@"Connected to \"%@\"", [grbl currentPort]]];
}

- (void)fileLoaded:(NSNotification *)notification
{
    fileGCode = [file gcode];
    
    [gcodeLayerSelection removeAllItems];
    [gcodeLayerSelection addItemWithTitle:@"All"];
    long layers = [[fileGCode layers] count];
    for (long i=0; i < layers; i++) {
        [gcodeLayerSelection addItemWithTitle:[NSString stringWithFormat:@"%ld", i+1]];
    }

    [gcodeView drawGCode:fileGCode];
    [gcodeView setNeedsDisplay:YES];
     
}

@end
