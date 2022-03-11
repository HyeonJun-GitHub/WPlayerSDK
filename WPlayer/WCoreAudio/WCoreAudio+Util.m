//
//  CAProcessor+Util.m
//  KTmPlayer
//
//  Created by 김현준 on 2017. 8. 23..
//  Copyright © 2017년 wally. All rights reserved.
//
#import "WCoreAudio+Util.h"

static float DEFAULT_PACKET_CNT = 38.2676048;
static int PRE_SEC = 60;

@implementation WCoreAudio(Util)

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration {
    WCoreAudio *ca = [WCoreAudio instance];
    if (!ca.isStreaming) {
        return [ca setUpCurrentTimeTotalPacket:ca.totalPacketCnt];
    }
    
    if (isProduct) {
        return [ca setUpCurrentTimeTotalPacket:ca.totalPacketCnt];
    }
    
    int total = [WCoreAudio GetTotalTime:isProduct :duration];
    return [ca setUpCurrentTimeTotalPacket:[WCoreAudio PreSongPacketCnt:total]];
    
}

+ (CGFloat)PreSongPacketCnt:(int)total {
    return total * DEFAULT_PACKET_CNT;
}

+ (CGFloat)GetTimeFromPacket:(CGFloat)time {
    return time/44100;
}

+ (CGFloat)GetTotalTime:(BOOL)isProduct :(CGFloat)fileDuration {
    WCoreAudio *ca = [WCoreAudio instance];
    if (!ca.isStreaming) {
        return [WCoreAudio GetTimeFromPacket:ca.totalPacketCnt];
    }
    
    //상품 체크
    int total = isProduct ? fileDuration : PRE_SEC;
    
    if (fileDuration <= PRE_SEC) {
        
        total = fileDuration;
        
        //59~60초 사이
        if (fileDuration >= PRE_SEC - 1) {
            total = PRE_SEC;    //1분으로 강제 세팅 //예전곡은 1분미리 듣기가 59초도 존재한다고함
        }
    }
    
    return total;
}

+ (CGFloat)GetDownloadSecFromTotalSec:(CGFloat)total {
    WCoreAudio *ca = [WCoreAudio instance];
    Float64 packet_cnt = ca.totalPacketCnt;
    
    //현재 다운로드 중이라면..
    if (ca.downloadingSize < 100) {
        Float64 downloadTimeScale = ca.downloadingSize/100;
        return total * downloadTimeScale;
    }
    
    return packet_cnt;
}

+ (CGFloat)GetCurrentTime:(CGFloat)total {
    WCoreAudio *ca = [WCoreAudio instance];
    if (!ca.isStreaming) {
        return [WCoreAudio GetTimeFromPacket:ca.currentPacketIdx];
    }
    BOOL isStreaming = ca.downloadingSize < 100;
    
    if (isStreaming) {
        total = floor([WCoreAudio GetDownloadSecFromTotalSec:total]);
    }
    
    Float64 secPacketCnt = ca.buffer.packetWriteIndex / total;
    return ca.currentPacketIdx / secPacketCnt;
}

+ (CGFloat)GetProcessorViewValue:(CGFloat)total {
    WCoreAudio *ca = [WCoreAudio instance];
    if (!ca.isStreaming) {
        return ca.currentTime;
    }
    
    BOOL isStreaming = ca.downloadingSize < 100;
    if (isStreaming) {
        Float64 secPacketCnt = floor([WCoreAudio GetDownloadSecFromTotalSec:total]);
        total = ca.buffer.packetWriteIndex / secPacketCnt * total;
    }else{
        total = ca.buffer.packetWriteIndex;
    }
    
    Float64 curTimePacket = ca.currentPacketIdx / total;
    return curTimePacket;
}

@end
