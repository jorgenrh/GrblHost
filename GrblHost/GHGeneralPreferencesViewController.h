//
//  GHGeneralPreferencesViewController.h
//  GrblHost
//
//  Created by JRH on 29.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface GHGeneralPreferencesViewController : NSViewController <MASPreferencesViewController>
{
    IBOutlet NSButton *confirmQuitCheckBox;
    IBOutlet NSButton *confirmQuitIfConnectedCheckBox;
    
    IBOutlet NSButton *useSoftwareResetCheckBox;
}

- (IBAction)saveCheckBoxState:(id)sender;
@end
