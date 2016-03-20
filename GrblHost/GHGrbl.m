//
//  GHGrbl.m
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHGrbl.h"
#import "GHSerial.h"
#import "GHGCodeCommand.h"
#import "GHGCodeImport.h"
#import "GHFile.h"

#import "GHAppDelegate.h"

NSString *const kGHGrblRead = @"GHGrblRead";
NSString *const kGHGrblReadLine = @"GHGrblReadLine";
NSString *const kGHGrblPortListUpdated = @"GHGrblPortListUpdated";
NSString *const kGHGrblConnected = @"GHGrblConnected";
NSString *const kGHGrblDisconnected = @"GHGrblDisconnected";



@implementation GHGrbl

@synthesize version, versionString;
@synthesize currentPort, currentBaud;
@synthesize X, Y, Z;
@synthesize feedRate, tool, layer;
@synthesize grblSettings;
@synthesize flag;
@synthesize commandHistory;



+ (GHGrbl *)sharedInstance {
    static GHGrbl *instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        serial = [[GHSerial alloc] initWithDelegate:self];
        grblSettings = [[NSMutableArray alloc] init];
        commandHistory = [[NSMutableArray alloc] init];
        connected = NO;
        responseCount = 0;
    }
    return self;
}




#pragma mark - Methods

- (void)addToHistory:(NSString *)string isResponse:(BOOL)res
{
    if (flag & kGHGrblSilent || internalFlag & kGHGrblSilent) {
        return;
    }
    
    //DLog(@"Adding history, com.count: %ld, rleft: %i", [commandHistory count], responseCount);
    
    if ([commandHistory count] == 0 && res) {
        responseCount = 0;
        return;
    }
    int responseIndex = (int)[commandHistory count]-responseCount;
    
    if ([commandHistory count] == 1) {
        responseIndex = 0;
    }
    
    if (res) {
        NSMutableDictionary *dict = [commandHistory objectAtIndex:responseIndex];
        [dict setObject:string forKey:@"response"];
        NSDate *time = (NSDate *)[dict objectForKey:@"time"];
        NSTimeInterval delay = [[NSDate date] timeIntervalSinceDate:time];
        [dict setObject:[NSString stringWithFormat:@"%f", delay] forKey:@"delay"];
        //[commandHistory replaceObjectAtIndex:responseIndex withObject:dict];
        DLog(@"Response added: %@", string);
        responseCount--;
    }
    else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSDate date], @"time",
                                     [NSString stringWithFormat:@"%ld", [string length]], @"size",
                                     @"n/a", @"delay",
                                     string, @"command",
                                     @"waiting...", @"response",
                                     nil];
        [commandHistory addObject:dict];
        DLog(@"Command added: %@", string);
        responseCount++;
    }
    //DLog(@"Added history, com.count: %ld, rleft: %i", [commandHistory count], responseCount);
    //[app->historyTable reloadData];
}

- (void)clearHistory
{
    [commandHistory removeAllObjects];
    responseCount = 0;
}

- (BOOL)extractVersion:(NSString *)string
{
    if ([string hasPrefix:@"Grbl "]) {
        
        NSString *fullVersion = [[[string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsSeparatedByString:@" "] lastObject];
        
        if ([fullVersion length]) {
            double ver;
            NSScanner *scanner = [[NSScanner alloc] initWithString:fullVersion];
            [scanner scanDouble:&ver];
            
            if (ver > 0) {
                version = ver;
                versionString = fullVersion;
                connected = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:kGHGrblConnected object:currentPort];

                [app->defaults setObject:currentPort forKey:@"SerialPortName"];
                [app->defaults setObject:[NSString stringWithFormat:@"%ld", currentBaud] forKey:@"SerialPortBaudRate"];
                //DLog(@"Full version: %@, num: %f", versionString, version);
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)extractSetting:(NSString *)string
{
    NSArray *parts = [[string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsSeparatedByString:@" "];
    
    if ([parts count] < 2) {
        return;
    }

    NSString *number = [[parts objectAtIndex:0] stringByReplacingOccurrencesOfString:@"$" withString:@""];
    
    if ([number rangeOfString:@"="].location != NSNotFound) {
        return;
    }
    
    NSString *value = [parts objectAtIndex:2];
    NSString *type = @"double";
    if ([string rangeOfString:@"."].location == NSNotFound) {
        type = @"integer";
    }
    
    NSString *description = nil;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
    [scanner scanUpToString:@"(" intoString:NULL];
    [scanner scanUpToString:@")" intoString:&description];

    NSMutableDictionary *setting = [NSMutableDictionary dictionaryWithObjectsAndKeys:number, @"number", value, @"value", description, @"description", type, @"type", nil];

    if ([number integerValue] < [grblSettings count]) {
        [grblSettings replaceObjectAtIndex:[number integerValue] withObject:setting];
    }
    else {
        [grblSettings insertObject:setting atIndex:[number integerValue]];
    }
}

- (void)updateGCodeData:(GHGCodeCommand *)command
{
    if ([command hasX]) X = [command X];
    if ([command hasY]) Y = [command Y];
    if ([command hasZ]) Z = [command Z];
    if ([command hasF]) feedRate = [command F];
    if ([command hasT]) tool = [command T];
    if ([command hasLayer]) layer = [command layer];
}

- (void)clearGCodeData
{
    X = Y = Z = 0;
    feedRate = tool = layer = 0;
}


- (void)setHome
{
    if ([self send:@"G92 X0 Y0 Z0"]) {
        [self clearGCodeData];
    }
}

- (void)goHome
{
    // G28
    if ([self send:@"G28 X0 Y0 Z0"]) {
        [self clearGCodeData];
    }
}

- (void)stop
{
    [self reset];
}



#pragma mark - Send Methods
//
// Send commands
//
- (BOOL)send:(NSString *)string
{
    return [self send:string withFlag:kGHGrblNone];
}

- (BOOL)send:(NSString *)string withFlag:(GHFlag)flags
{
    flag = flags;
    GHGCodeImport *importer = [[GHGCodeImport alloc] init];
    GHGCodeCommand *command = [importer parseGcodeString:string];
    [self addToHistory:string isResponse:NO];
    [self updateGCodeData:command];
    return [self writeString:string];
}

- (BOOL)sendCommand:(GHGCodeCommand *)command withFlag:(GHFlag)flags
{
    flag = flags;
    [self addToHistory:[command gcodeString] isResponse:NO];
    [self updateGCodeData:command];
    return [self writeString:[command gcodeString]];
}

- (BOOL)writeString:(NSString *)string
{
    if (![self isConnected]) {
        return NO;
    }
    
    if ([string hasPrefix:@"$"]) {
        internalFlag = [string length] > 2 ? kGHGrblSettingsSave : kGHGrblSettingsRequest;
    }
    
    unichar last = [string characterAtIndex:[string length]-1];
    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]) {
        string = [NSString stringWithFormat:@"%@\n", string];
    }
    
    if ([serial writeString:string]) {
        return YES;
    }

    return NO;
}



#pragma mark - Serial methods

- (BOOL)connectTo:(NSString *)portName withBaudRate:(long)baudRate
{
    if ([serial connectTo:portName withBaudRate:baudRate]) {
        currentPort = portName;
        currentBaud = baudRate;
        return YES;
    }
    return NO;
}

- (void)disconnect
{
    connected = NO;
    return [serial disconnect];
}

- (BOOL)isConnected
{
    return ([serial isConnected] && connected);
}

- (void)reset
{
    BOOL softReset = [app->defaults boolForKey:@"UseSoftwareReset"];
    if (version >= 0.8 && softReset) {
        [serial writeString:[NSString stringWithFormat:@"%c", 0x18]];
    }
    else {
        [self clearGCodeData];
        [serial reset];
    }
}

- (NSArray *)deviceNames
{
    return [serial deviceNames];
}

- (NSArray *)baudRates
{
    return [serial baudRates];
}



#pragma mark - Delegate methods

- (void)serialRead:(NSString *)string
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kGHGrblRead object:string];
}

- (void)serialReadLine:(NSString *)string
{
    if (!connected && ![self extractVersion:string]) {
        return;
    }
    
    if (internalFlag & kGHGrblSettingsRequest) {
        [self extractSetting:string];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kGHGrblReadLine object:string];
    
    if ([string hasPrefix:@"ok"] || [string hasPrefix:@"error"]) {
        //DLog(@"Got response! %@", string);
        //DLog(@"History: %ld, Responses: %i", [commandHistory count], responseCount);
        if (!(flag & kGHGrblSilent) && !(internalFlag & kGHGrblSilent)) {
            [self addToHistory:string isResponse:YES];
        }
        internalFlag = flag = kGHGrblNone;
    }
    

}

- (void)portClosed
{
    DLog(@"Ported closed");
    if (responseCount > 0) {
        for (unsigned long i=0; i < responseCount; i++) {
            [self addToHistory:@"n/a" isResponse:YES];
        }
    }
    connected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kGHGrblDisconnected object:nil];
}

- (void)portListChanged:(NSArray *)ports
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kGHGrblPortListUpdated object:ports];
}


@end
