//
//  GHSerialDelegate.h
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMSerialPort;

@protocol GHSerialDelegate <NSObject>
- (void)serialReadLine:(NSString *)string;
- (void)serialRead:(NSString *)string;
- (void)portClosed;
- (void)portListChanged:(NSArray *)ports;
@end

@interface GHSerial : NSObject
{
    id<GHSerialDelegate> delegate;
    AMSerialPort *serialPort;
    NSArray *baudRates;
    NSMutableArray *serialBuffer;
}

@property (readwrite) id<GHSerialDelegate> delegate;
@property (readonly) NSArray *baudRates;

- (id)initWithDelegate:(id<GHSerialDelegate>)_delegate;

- (BOOL)connectTo:(NSString *)portName withBaudRate:(long)baudRate;
- (void)disconnect;

- (BOOL)isConnected;

- (BOOL)writeString:(NSString *)string;

- (void)reset;


- (NSArray *)deviceNames;


@end
