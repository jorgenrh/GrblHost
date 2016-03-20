//
//  GHGCodeImport.m
//  GCodeViewer
//
//  Created by JRH on 19.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGCodeImport.h"
#import "GHGCodeCommand.h"
#import "GHGCode.h"

@implementation GHGCodeImport

@synthesize gcodeData, sourceFilePath;

- (id)initWithFile:(NSString *)filePath
{
    self = [super init];
    if (self) {
        [self setSourceFilePath:filePath];
        [self setGcodeData:[NSData dataWithContentsOfFile:sourceFilePath]];
    }
    return self;
}


- (GHGCode *)analyzeGcode
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:sourceFilePath]) {
        return nil;
    }
    [self setGcodeData:[NSData dataWithContentsOfFile:sourceFilePath]];
    
    
    NSString *gcodeString = [[NSString alloc] initWithData:gcodeData encoding:NSUTF8StringEncoding];
    NSArray *gcodeLines = [gcodeString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    GHGCode *gcode = [[GHGCode alloc] init];
    
    //int i = 0;
    float currentZ = 0.0;
    
    NSMutableDictionary *layers = [[NSMutableDictionary alloc] init];
    
    for (NSString *line in gcodeLines) {
        GHGCodeCommand *parsedCmd = [self parseGcodeString:line];
        if (parsedCmd != nil) {
            
            if ([parsedCmd hasZ]) {
                currentZ = [parsedCmd Z];
            }

            if ([parsedCmd hasX] || [parsedCmd hasY]) {

                NSString *layerString = [NSString stringWithFormat:@"%f", currentZ];

                int layer = 1;
                int numLayer = 1;
                for (NSString *key in [layers allKeys]) {
                    NSDictionary *dict = [layers objectForKey:key];
                    if ([dict objectForKey:layerString]) {
                        //DLog(@"Found key %@", layerString);
                        layer = [key intValue];
                        numLayer = [[dict objectForKey:layerString] intValue]+1;
                        //DLog(@"Num key %i, numLayers %i", layer, numLayer);
                        break;
                    }
                    else {
                        layer++;
                    }
                }
                NSDictionary *layerData = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%i", numLayer] forKey:layerString];
                [layers setObject:layerData forKey:[NSString stringWithFormat:@"%i", layer]];
            
                //DLog(@"Layer: %@ (%i)", layerString, layer);
            
                [parsedCmd setLayer:layer];
                //DLog(@"setting layer %i", layer);
            }
            
            
            [parsedCmd setGcodeString:line];
            
            [gcode addCommand:parsedCmd];
            //DLog(@"Layer %i: %@", layer, line);
            //if (++i > 25) break;
        }
    }
    
    [gcode setLayers:layers];
    
    return gcode;
}

- (GHGCodeCommand *)parseGcodeString:(NSString *)str
{
    NSString *string = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //NSArray *tokens = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    GHGCodeCommand *gcodeCmd = [[GHGCodeCommand alloc] init];

    NSString *expression = @"([XYZGIJKFT]{1})([-.0-9]{1,})";
    
    //NSString *searchedString = input;
    NSError* error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    //D
    BOOL coordsUpdate = NO;
    
    //int i = 0;
    for (NSTextCheckingResult* match in matches) {
        
        NSString *axis = [[string substringWithRange:[match rangeAtIndex:1]] uppercaseString];
        NSString *coordsString = [string substringWithRange:[match rangeAtIndex:2]];
        double coords = [coordsString doubleValue];
        
        //DLog(@"Axis: %@, Coords: %f (%@)", axis, coords, coordsString);
        
        if ([axis isEqualToString:@"X"]) {
            [gcodeCmd setX:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"Y"]) {
            [gcodeCmd setY:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"Z"]) {
            [gcodeCmd setZ:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"I"]) {
            [gcodeCmd setI:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"J"]) {
            [gcodeCmd setJ:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"K"]) {
            [gcodeCmd setK:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"F"]) {
            [gcodeCmd setF:coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"G"]) {
            [gcodeCmd setG:(int)coords];
            coordsUpdate = YES;
        }
        else if ([axis isEqualToString:@"T"]) {
            [gcodeCmd setG:(int)coords];
            coordsUpdate = YES;
        }
        
        //DLog(@"Found %@ with %f (row: %i)", axis, coords, ++i);
    }
    
    return (coordsUpdate ? gcodeCmd : nil);
    //DLog(@"Coords:\nX: %f\nY: %f\nZ: %f", Xcoord, Ycoord, Zcoord);
}



@end
