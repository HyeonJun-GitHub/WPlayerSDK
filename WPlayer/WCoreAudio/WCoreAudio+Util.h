//
//  CAProcessor+Util.h
//  KTmPlayer
//
//  Created by 김현준 on 2017. 8. 23..
//  Copyright © 2017년 wally. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "WCoreAudio.h"
#import "WPlayer.h"

@interface WCoreAudio(Util)

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration;
+ (CGFloat)PreSongPacketCnt:(int)total;
+ (CGFloat)GetTimeFromPacket:(CGFloat)time;
+ (CGFloat)GetTotalTime:(BOOL)isProduct :(CGFloat)fileDuration;
+ (CGFloat)GetCurrentTime:(CGFloat)total;
+ (CGFloat)GetDownloadSecFromTotalSec:(CGFloat)total;
/**
 초당 패킷 * 전체시간
 
 @param total 전체시간
 @return 0~1 사이로 현재위치 반환
 */
+ (CGFloat)GetProcessorViewValue:(CGFloat)total;

@end
