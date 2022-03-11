//
//  CAParser.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class CAParser;

@protocol CAParserDelegate <NSObject>

- (void)audioStreamParser:(CAParser *)inParser didObtainStreamDescription:(AudioStreamBasicDescription *)inDescription;
- (void)audioStreamParser:(CAParser *)inParser packetData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount;

@end

@interface CAParser : NSObject

- (void)parseClose;
- (void)parseData:(NSData *)inData;
- (void)parseData:(const void*)byte length:(UInt32)length;
@property (weak, nonatomic) id <CAParserDelegate> delegate;
@property (assign, nonatomic) AudioFileStreamID audioFileStreamID;
- (id)initWithType:(AudioFileTypeID)type;
@end
