//
//  GAEngine+Util.m
//  Wally
//
//  Created by 김현준 on 09/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "WAudioEngine+Util.h"

static float DEFAULT_PACKET_CNT = 38.2676048;
static int PRE_SEC = 60;

@implementation WAudioEngine(Util)
+ (BOOL)isFinish:(BOOL)isProduct :(float)duration {
    WAudioEngine *engine = [WAudioEngine instance];
    if (!engine.isStreaming) {
        return [engine setUpCurrentTimeTotalPacket:engine.totalPacketCnt];
    }
    
    if (isProduct) {
        return [engine setUpCurrentTimeTotalPacket:engine.totalPacketCnt];
    }
    
    int total = [WAudioEngine GetTotalTime:isProduct :duration];
    return [engine setUpCurrentTimeTotalPacket:[WAudioEngine PreSongPacketCnt:total]];
}

+ (CGFloat)PreSongPacketCnt:(int)total {
    return total * DEFAULT_PACKET_CNT;
}

+ (CGFloat)GetTimeFromPacket:(CGFloat)time {
    return time/44100;
}

+ (CGFloat)GetTotalTime:(BOOL)isProduct :(CGFloat)fileDuration {
    WAudioEngine *engine = [WAudioEngine instance];
    if (!engine.isStreaming) {
        return [WAudioEngine GetTimeFromPacket:engine.totalPacketCnt];
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
    WAudioEngine *engine = [WAudioEngine instance];
    Float64 packet_cnt = engine.totalPacketCnt;
    
    //현재 다운로드 중이라면..
    if (engine.downloadingSize < 100) {
        Float64 downloadTimeScale = engine.downloadingSize/100;
        return total * downloadTimeScale;
    }
    
    return packet_cnt;
}

+ (CGFloat)GetCurrentTime:(CGFloat)total {
    WAudioEngine *engine = [WAudioEngine instance];
    if (!engine.isStreaming) {
        return [WAudioEngine GetTimeFromPacket:engine.currentPacketIdx];
    }
    BOOL isStreaming = engine.downloadingSize < 100;
    
    if (isStreaming) {
        total = floor([WAudioEngine GetDownloadSecFromTotalSec:total]);
    }
    
    Float64 secPacketCnt = engine.buffer.packetWriteIndex / total;
    return engine.currentPacketIdx / secPacketCnt;
}

+ (CGFloat)GetProcessorViewValue:(CGFloat)total {
    WAudioEngine *engine = [WAudioEngine instance];
    if (!engine.isStreaming) {
        return engine.currentTime;
    }
    
    BOOL isStreaming = engine.downloadingSize < 100;
    if (isStreaming) {
        Float64 secPacketCnt = floor([WAudioEngine GetDownloadSecFromTotalSec:total]);
        total = engine.buffer.packetWriteIndex / secPacketCnt * total;
    }else{
        total = engine.buffer.packetWriteIndex;
    }
    
    Float64 curTimePacket = engine.currentPacketIdx / total;
    return curTimePacket;
}

@end
