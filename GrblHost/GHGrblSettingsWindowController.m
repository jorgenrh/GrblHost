//
//  GHGrblSettingsWindowController.m
//  GrblHost
//
//  Created by JRH on 29.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGrblSettingsWindowController.h"
#import "GHGrbl.h"

@interface GHGrblSettingsWindowController ()

@end

@implementation GHGrblSettingsWindowController


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grblReadLine:) name:kGHGrblReadLine object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grblConnected:) name:kGHGrblConnected object:nil];
        grbl = [GHGrbl sharedInstance];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [progressIndicator startAnimation:self];
    [progressIndicator setHidden:YES];
    if ([grbl isConnected]) {
        DLog(@"Requesting");
        [self requestSettings];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

- (void)refreshSettings:(id)sender
{
    [progressIndicator startAnimation:self];
    [progressIndicator setHidden:NO];
    [self requestSettings];
}

- (void)requestSettings
{
    [grbl send:@"$" withFlag:(kGHGrblSettingsRequest | kGHGrblSilent)];
}

- (void)saveSetting:(NSString *)setting
{
    [grbl send:setting withFlag:kGHGrblSettingsSave];
}

#pragma mark TableView Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[grbl grblSettings] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *dict = [[grbl grblSettings] objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    return [dict valueForKey:identifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *dict = [[grbl grblSettings] objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    [dict setValue:object forKey:identifier];
    DLog(@"Object edited");
    
    NSString *command = [NSString stringWithFormat:@"$%@=%@", [dict valueForKey:@"number"], object];
    [self saveSetting:command];
}


#pragma mark Notification Methods

- (void)grblReadLine:(NSNotification *)notification
{
    NSString *response = (NSString *)[notification object];
    
    if ([grbl flag] & kGHGrblSettingsRequest) {
        if ([response hasPrefix:@"ok"] || [response hasPrefix:@"error"]) {
            [settingsTable reloadData];
            [progressIndicator setHidden:YES];
        }
    }
    
    if ([grbl flag] & kGHGrblSettingsSave) {
            DLog(@"Response: %@", response);
            if ([response hasPrefix:@"error"]) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Settings Error"];
                [alert setInformativeText:response];
                [alert addButtonWithTitle:@"OK"];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
                //[settingsTable reloadData];
            }
    }
    
    
}

- (void)grblConnected:(NSNotification *)notification
{
    [self requestSettings];
}



@end
