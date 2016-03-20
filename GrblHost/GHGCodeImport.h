//
//  GHGCodeImport.h
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GHGCode;
@class GHGCodeCommand;

@interface GHGCodeImport : NSObject
{
    //GHGCode *gcode;
    
    NSData *gcodeData;
    NSString *sourceFilePath;
    
    NSMutableArray *gcodeCommands;
}

@property NSData *gcodeData;
@property NSString *sourceFilePath;


- (id)initWithFile:(NSString *)filePath;
- (GHGCodeCommand *)parseGcodeString:(NSString *)string;
- (GHGCode *)analyzeGcode;

@end
