//
//  GAEngine+Util.h
//  Wally
//
//  Created by 김현준 on 09/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAudioEngine.h"
NS_ASSUME_NONNULL_BEGIN

@interface WAudioEngine(Util)

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration;
+ (CGFloat)PreSongPacketCnt:(int)total;
+ (CGFloat)GetTimeFromPacket:(CGFloat)time;
+ (CGFloat)GetTotalTime:(BOOL)isProduct :(CGFloat)fileDuration;
+ (CGFloat)GetCurrentTime:(CGFloat)total;
/**
 초당 패킷 * 전체시간
 
 @param total 전체시간
 @return 0~1 사이로 현재위치 반환
 */
+ (CGFloat)GetProcessorViewValue:(CGFloat)total;

@end
NS_ASSUME_NONNULL_END
