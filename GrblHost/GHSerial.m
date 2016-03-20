//
//  GHSerialDelegate.m
//  GrblHost
//
//  Created by JRH on 27.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#import "GHSerial.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

@implementation GHSerial

@synthesize delegate, baudRates;

- (id)initWithDelegate:(id<GHSerialDelegate>)_delegate
{
    self = [super init];
    if (self) {
        delegate = _delegate;
        
        // Add notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
        
        // Initialize port list
        [AMSerialPortList sharedPortList];
        
        baudRates = [NSArray arrayWithObjects: //@"0",
                     @"50", @"75", @"110", @"134", @"150", @"200",
                     @"300", @"600", @"1200", @"1800", @"2400", @"4800",
                     @"7200", @"9600", @"14400", @"19200", @"28800",
                     @"38400", @"57600", @"76800", @"115200", @"230400", nil];
        
        serialBuffer = [[NSMutableArray alloc] init];
    }
    return self;
}


- (BOOL)connectTo:(NSString *)portName withBaudRate:(long)baudRate
{
    if (![portName isEqualToString:[serialPort bsdPath]]) {
        [serialPort close];
        
        serialPort = [[AMSerialPort alloc] init:portName withName:portName type:(NSString*)CFSTR(kIOSerialBSDModemType)];
        [serialPort setDelegate:self];
        
        if ([serialPort open]) {
            
            // Default baud rate for this will be 115200
            [serialPort setSpeed:baudRate];
            NSLog(@"Baudrate: %lu", baudRate);
            // Listen for the data in a sepperate thread
            [serialPort readDataInBackground];
            
            return YES;
            
        } else { // An error occured while creating port
            
            serialPort = nil;
            
        }
    } else {
        DLog(@"Unknown error.");
    }
    
    return NO;
}

- (void)disconnect
{
    [serialPort close];
}

- (BOOL)isConnected
{
    return [serialPort isOpen];
}


- (BOOL)writeString:(NSString *)string
{
    
    NSError *error = nil;
    
    if ([serialPort isOpen]) {
        [serialPort writeString:string usingEncoding:NSUTF8StringEncoding error:&error];
    } else {
        DLog(@"Port not open");
        return NO;
    }
    
    if(error != nil) {
        DLog(@"Error sending the data: %@", [error localizedDescription]);
        return NO;
    }
    
    return YES;
}


- (NSArray *)deviceNames
{
    NSEnumerator *enumerator = [AMSerialPortList portEnumerator];
    NSMutableArray *allDevices = [[NSMutableArray alloc] init];
    AMSerialPort *port;
    
    while (port = [enumerator nextObject]) {
        [allDevices addObject:[port bsdPath]];
    }
    
    //DLog(@"All devices: %@", allDevices);
    return [NSArray arrayWithArray:allDevices];
}

- (void)reset
{
    DLog(@"reset connection");
    [serialPort clearDTR];
    [serialPort setDTR];
}


- (void)serialPortReadData:(NSDictionary *)dataDictionary

{
	// this method is called if data arrives
	// @"data" is the actual data, @"serialPort" is the sending port
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
    
	if ([data length] > 0) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        // Send complete lines
        // TODO: use AMSerialPort's readUpToChar
        int bufferSize = 16;
        NSRange range = NSMakeRange(0, bufferSize);
        NSUInteger end = [text length];
        while (range.location < end)
        {
            unichar buffer[bufferSize];
            if (range.location + range.length > end)
            {
                range.length = end - range.location;
            }
            [text getCharacters: buffer range: range];
            range.location += bufferSize;
            for (unsigned i=0 ; i<range.length ; i++)
            {
                unichar c = buffer[i];
                [serialBuffer addObject:[NSString stringWithFormat:@"%c", c]];
                
                if (c == '\n') {
                    NSString *line = [serialBuffer componentsJoinedByString:@""];
                    //DLog(@"NEW LINE: \"\"%@\"\"", line);
                    [serialBuffer removeAllObjects];
                    [delegate serialReadLine:line];
                    //[[NSNotificationCenter defaultCenter] postNotificationName:kGHSerialReadLine object:line];
                }
                
            }
        }
        //[[NSNotificationCenter defaultCenter] postNotificationName:kGHSerialRead object:text];
        [delegate serialRead:text];
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
        [delegate portClosed];
		//[outputTextView insertText:@"port closed\r"];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kGHSerialPortClosed object:nil];
	}
}


- (void)didAddPorts:(NSNotification *)notification
{
    DLog(@"Port added");
    NSArray *ports = [[notification userInfo] objectForKey:AMSerialPortListAddedPorts];
    
    NSMutableArray *portNames = [[NSMutableArray alloc] init];
    
    for(AMSerialPort *aPort in ports) {
        [portNames addObject:[aPort bsdPath]];
    }
    
    [delegate portListChanged:portNames];
}

- (void)didRemovePorts:(NSNotification *)notification
{
    DLog(@"Port removed");
    NSArray *ports = [[notification userInfo] objectForKey:AMSerialPortListRemovedPorts];
    
    NSMutableArray *portNames = [[NSMutableArray alloc] init];
    
    for(AMSerialPort *aPort in ports) {
        [portNames addObject:[aPort bsdPath]];
    }

    [delegate portListChanged:portNames];
}


@end
