//
//  GHGrbl.h
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHSerial.h"

extern NSString *const kGHGrblRead;
extern NSString *const kGHGrblReadLine;
extern NSString *const kGHGrblPortListUpdated;
extern NSString *const kGHGrblConnected;
extern NSString *const kGHGrblDisconnected;


typedef enum {
    kGHGrblNone = 0,
    kGHGrblSilent = 1,
    kGHGrblFileCommand = 2,
    kGHGrblSettingsRequest = 4,
    kGHGrblSettingsSave = 8,
    kGHGrblNoResponseExpected = 16
} GHFlag;

@class GHGCodeCommand;
@class GHFile;

@interface GHGrbl : NSObject <GHSerialDelegate>
{
    GHSerial *serial;
    GHFile *file;
    
    double version;
    NSString *versionString;
    
    double X, Y, Z;
    int feedRate, tool, layer;
    
    BOOL connected;

    NSString *currentPort;
    long currentBaud;
        
    NSMutableArray *grblSettings;
    
    NSMutableArray *commandHistory;
    int responseCount;
    
    GHFlag flag;
    GHFlag internalFlag;
    
    char specialCommand;
    BOOL sendSpecialCommand;
}

@property (readonly) double version;
@property (readonly) NSString *versionString;
@property (assign) long currentBaud;
@property (readonly) NSString *currentPort;
@property (readonly) double X, Y, Z;
@property (readonly) int feedRate, tool, layer;
@property (readwrite) NSMutableArray *grblSettings;
@property (readwrite) GHFlag flag;
@property (readonly) NSMutableArray *commandHistory;


+ (GHGrbl *)sharedInstance;

// Grbl methods
- (void)addToHistory:(NSString *)string isResponse:(BOOL)res;
- (void)clearHistory;

- (BOOL)extractVersion:(NSString *)string;
- (void)extractSetting:(NSString *)string;

- (void)updateGCodeData:(GHGCodeCommand *)command;
- (void)clearGCodeData;

- (void)setHome;
- (void)goHome;
- (void)stop;

// Serial send methods
- (BOOL)send:(NSString *)string;
- (BOOL)send:(NSString *)string withFlag:(GHFlag)flags;
- (BOOL)sendCommand:(GHGCodeCommand *)command withFlag:(GHFlag)flags;
- (BOOL)writeString:(NSString *)string;

// Serial methods
- (BOOL)connectTo:(NSString *)portName withBaudRate:(long)baudRate;
- (void)disconnect;
- (BOOL)isConnected;
- (void)reset;
- (NSArray *)deviceNames;
- (NSArray *)baudRates;

@end
