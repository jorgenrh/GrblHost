//
//  GHGeneralPreferencesViewController.m
//  GrblHost
//
//  Created by JRH on 29.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGeneralPreferencesViewController.h"
#import "GHAppDelegate.h"

@interface GHGeneralPreferencesViewController ()

@end

@implementation GHGeneralPreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (id)init
{
    return [super initWithNibName:@"GHGeneralPreferencesView" bundle:nil];
}

- (void)awakeFromNib
{
    [confirmQuitCheckBox setState:[app->defaults boolForKey:@"ConfirmQuit"]];
    [confirmQuitIfConnectedCheckBox setEnabled:[app->defaults boolForKey:@"ConfirmQuit"]];
    [confirmQuitIfConnectedCheckBox setState:[app->defaults boolForKey:@"ConfirmQuitIfConnected"]];
    
    [useSoftwareResetCheckBox setState:[app->defaults boolForKey:@"UseSoftwareReset"]];
}


#pragma mark - IBAction methods

- (void)saveCheckBoxState:(id)sender
{
    NSString *key = [sender identifier];
    if ([key length]) {
        if ([key isEqualToString:@"ConfirmQuit"]) {
            [confirmQuitIfConnectedCheckBox setEnabled:[sender state]];
        }
     
        [app->defaults setBool:[sender state] forKey:key];
    
    }
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end
