//
//  CABuffer.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CABuffer.h"
#include "CAUtils.h"
#import "CADebug.h"

@implementation CABuffer

BOOL CheckBuffer(CABuffer *buffer) {
    return buffer.currentPacketInfo.packetDescription.mDataByteSize == 0 ? NO : YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        _packets = 0;
        _packetReadIndex = 0;
        _packetWriteIndex = 0;
        _packetCount = 2048*2;
        self.packets = (AudioPacketInfo *)calloc(_packetCount, sizeof(AudioPacketInfo));
    }
    return self;
}

- (id)initWithPacketCount:(NSInteger)packetCount;
{
    self = [super init];
    if (self) {
        _packets = 0;
        _packetCount = packetCount*2;//2048;
        self.packets = (AudioPacketInfo *)calloc(_packetCount, sizeof(AudioPacketInfo));
    }
    return self;
}

- (void)storePacketData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount
{
    @synchronized (self) {
        
        for (size_t index = 0; index < inPacketsCount; index ++) {
            
            if (_packetWriteIndex >= _packetCount) {
                size_t oldSize = _packetCount * sizeof(AudioPacketInfo);
                _packetCount = _packetCount * 2;
                self.packets = (AudioPacketInfo *)realloc(self.packets, _packetCount * sizeof(AudioPacketInfo));
                bzero((void *)self.packets + oldSize, oldSize);
            }
            AudioStreamPacketDescription emptyDescription;
            
            if (!inPacketDescriptions) {
                emptyDescription.mStartOffset = index;
                emptyDescription.mDataByteSize = 1;
                emptyDescription.mVariableFramesInPacket = 0;
            }
            
            AudioStreamPacketDescription *currentDescription = inPacketDescriptions ? &(inPacketDescriptions[index]) : &emptyDescription;
            
            AudioPacketInfo *nextInfo = &self.packets[_packetWriteIndex];
            @try {
                CAudioPacketInfoFree(nextInfo);
            }@catch (NSException *exception) {
                
            }
            
            nextInfo->data = malloc(currentDescription->mDataByteSize);
            NSAssert(nextInfo->data, @"current packet에 메모리 할당 해야합니다.");
            memcpy(nextInfo->data, inBytes + currentDescription->mStartOffset, currentDescription->mDataByteSize);
            memcpy(&nextInfo->packetDescription, currentDescription, sizeof(AudioStreamPacketDescription));
            
            _packetWriteIndex++;
            
            availablePacketCount++;
        }
    }
}

- (void)setPacketReadIndex:(size_t)inNewIndex
{
    size_t max = availablePacketCount;
    
    if (inNewIndex > max) {
        _packetReadIndex = max;
        return;
    }
    
    if (inNewIndex < _packetWriteIndex) {
        _packetReadIndex = inNewIndex;
    }
    else {
        _packetReadIndex = _packetWriteIndex;
    }
}

- (void)movePacketReadIndex
{
    [self setPacketReadIndex:_packetReadIndex + 1];
}

- (AudioPacketInfo)currentPacketInfo
{
    return self.packets[_packetReadIndex];
}

- (void)initPackets {
    
    if (availablePacketCount == 0) {
        return;
    }
    
    size_t freePacketCnt = availablePacketCount;
    
    if (availablePacketCount > _packetWriteIndex) {
        freePacketCnt = _packetWriteIndex;
    }
    
    if (!_packets) {
        return;
    }
    
    @try {
        for (int i = 0; i < freePacketCnt + 1; i++) {
            AudioPacketInfo *info = &self.packets[i];
            if (info == NULL) {
                continue;
                
                /*
                 return;
                 프리종료를 하기엔 위허함, 안전하게 continue로 하자,
                 중간에 데이터가 빠지는 케이스(통신장애 + 다음곡 진행)가 존재할수도 있음
                 */
            }
            
            CAudioPacketInfoFree(info);
        }
        free(self.packets);
        _packetReadIndex = 0;
        _packetWriteIndex = 0;
    }@catch (NSException *exception) {
        
    }
}

@synthesize delegate;
@synthesize currentPacketInfo;

@end
