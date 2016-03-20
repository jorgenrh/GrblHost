//
//  GHGrblPreferencesViewController.m
//  GrblHost
//
//  Created by JRH on 29.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGrblPreferencesViewController.h"

@interface GHGrblPreferencesViewController ()

@end

@implementation GHGrblPreferencesViewController

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
    return [super initWithNibName:@"GHGrblPreferencesView" bundle:nil];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"GrblPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Grbl", @"Toolbar item name for the Grbl preference pane");
}

@end
