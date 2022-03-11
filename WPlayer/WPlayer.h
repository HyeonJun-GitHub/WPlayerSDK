//
//  GPlayerHelper.h
//  Wally
//
//  Created by 김현준 on 20/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAConfig.h"
#import "CAUnit.h"
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#endif
NS_ASSUME_NONNULL_BEGIN

enum AudioPlayerType {
    AVAudioEngineType = 0,
    CoreAudioType,
    AVPlayerType,
};

static NSString * const PlayerStateNotify = @"PlayerStateNotify";
@class SongFileInfo;
@interface WPlayer : NSObject

enum PlayerState {
    START,
    PLAYING,
    PAUSE,
    STOP,
    NONE,
    ERROR,
};

enum SoundState {
    CASoundStateOutPut = 0,
    CASoundStateMute,
};


/// AVPlayerMode를 사용했을경우 EQ는 사용불가능합니다.
@property (nonatomic, assign, readonly) BOOL canEQ;
@property (nonatomic, assign) enum AudioPlayerType playerType;


/**
 플레이어 선택
 
 @param player 원하는 플레이어 선택
 */
//NSString *InitAudioPlayer(enum AudioPlayerType player);
+ (NSString *)initAudioPlayer:(enum AudioPlayerType)player;

id AudioPlayerInstance(void);
Class PlayerClass(void);
+ (WPlayer *)instance;

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration;
CGFloat GetTotalTime(BOOL isProduct,CGFloat fileDuration);
CGFloat GetCurrentTime(CGFloat total);

/**
 초당 패킷 * 전체시간
 
 @param total 전체시간
 @return 0~1 사이로 현재위치 반환
 */
CGFloat GetProcessorViewValue(CGFloat total);

+ (enum PlayerState)playState;
+ (void)pause;
+ (void)songStop;
+ (void)moveToSeek:(CGFloat)seekPacket;
+ (void)addTarget:(id)target;
+ (BOOL)playWithUrl:(NSString *)url;
+ (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option;
+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option;
+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler;
+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler;
+ (NSString *)streamingUrl;
+ (dispatch_queue_t)player_q;

#pragma mark - EQ

/// 필터를 적용합니다.
/// @param value Ref : AudioUnitParameter
/// @param FilterType Ref : AudioUnitParameter
void SetUpAudioUnitFilterValue(Float32 value, struct AudioEffecGroupType FilterType);

/// EQ를 적용합니다.
/// @param value -96dB ~ 26dB
/// @param eQBandNum 밴드넘버
void SetUpAudioUnitEQValue(Float32 value, UInt32 eQBandNum);

void SetUpAudioUnitEQGlobalValue(Float32 value);

#pragma mark - Volume

/**
 CABandEQ Gain로 소리크기를 변경합니다. 볼륨값을 메모리에 저장합니다.
 @param value 0~1
 */

__attribute__((overloadable)) void SoundVolume(Float64 value);


/**
 CABandEQ Gain로 소리크기를 변경합니다.
 @param value 0~1
 @param isTemp 볼륨값 메모리에 저장여부
 */
__attribute__((overloadable)) void SoundVolume(Float64 value,BOOL isTemp);


/**
 CABandEQ Gain로 소리크기를 가져옵니다.
 @return 볼륨값
 */
__attribute__((overloadable)) Float32 SoundVolume(void);

//Float32 a = SoundVolume();


@end

NS_ASSUME_NONNULL_END
