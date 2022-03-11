//
//  CABuffer.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAUtils.h"

@class CABuffer;

@protocol CABufferDelegate <NSObject>

- (AudioStreamBasicDescription)usedAudioStreamBasicDescription;
- (void)audioBufferDidBeginReadPacket:(CABuffer *)inBuffer;

@end

@interface CABuffer : NSObject {
    
    NSUInteger availablePacketCount;
    
    NSUInteger packetReadHead;
    NSUInteger readPacketIndex;
}
@property (nonatomic,assign) AudioPacketInfo *packets;
@property (nonatomic,assign,readonly) size_t packetWriteIndex;
@property (nonatomic,assign,readonly) size_t packetReadIndex;
@property (nonatomic,assign,readonly) size_t packetCount;
@property (weak, nonatomic) id <CABufferDelegate> delegate;
@property (readonly, nonatomic) AudioPacketInfo currentPacketInfo;

BOOL CheckBuffer(CABuffer *buffer);
- (void)initPackets;
- (id)initWithPacketCount:(NSInteger)packetCount;
- (void)storePacketData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount;
- (void)movePacketReadIndex;
- (void)setPacketReadIndex:(size_t)inNewIndex;
@end
