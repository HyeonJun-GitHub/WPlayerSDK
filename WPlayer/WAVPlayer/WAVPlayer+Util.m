//
//  GAVPlayer+Util.m
//  Wally
//
//  Created by 김현준 on 16/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "WAVPlayer+Util.h"

@implementation WAVPlayer(Util)

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration {
    WAVPlayer *player = [WAVPlayer instance];
    return [player isCheckPlayed];
}

+ (CGFloat)PreSongPacketCnt:(int)total {
    return total * DEFAULT_PACKET_CNT;
}

+ (CGFloat)GetTimeFromPacket:(CGFloat)time {
    return 0;
}

+ (CGFloat)GetTotalTime:(BOOL)isProduct :(CGFloat)fileDuration {
    WAVPlayer *player = [WAVPlayer instance];
    if (!player.isStreaming) {
        return CMTimeGetSeconds(player.player.currentItem.duration);
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
    WAVPlayer *player = [WAVPlayer instance];
    Float64 packet_cnt = player.totalPacketCnt;
    
    //    //현재 다운로드 중이라면..
    //    if (player.downloadingSize < 100) {
    //        Float64 downloadTimeScale = player.downloadingSize/100;
    //        return total * downloadTimeScale;
    //    }
    
    return packet_cnt;
}

+ (CGFloat)GetCurrentTime:(CGFloat)total {
    WAVPlayer *player = [WAVPlayer instance];
    CMTime time = player.player.currentTime;
    CGFloat sec = CMTimeGetSeconds(time);
    if (isnan(sec))return 0;
    return sec;
}

+ (CGFloat)GetProcessorViewValue:(CGFloat)total {
    WAVPlayer *player = [WAVPlayer instance];
    CMTime time = player.player.currentTime;
    CGFloat sec = CMTimeGetSeconds(time);
    if (isnan(sec))return 0;
    return sec/total;
}

@end
