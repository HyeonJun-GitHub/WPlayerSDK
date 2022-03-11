//
//  GPlayerHelper.m
//  Wally
//
//  Created by 김현준 on 20/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "WPlayer.h"

#import "WAVPlayer.h"
#import "WAVPlayer+Util.h"

#import "WAudioEngine.h"
#import "WAudioEngine+Util.h"

#import "WCoreAudioH.h"

static Class AudioPlayer = nil;

@implementation WPlayer

SINGLETON(WPlayer, instance);

+ (NSString *)initAudioPlayer:(enum AudioPlayerType)playerType {
//NSString *InitAudioPlayer(enum AudioPlayerType playerType) {
    [[WPlayer instance] setPlayerType:playerType];
    if (playerType == CoreAudioType)    {[WPlayer setAudioPlayer:WCoreAudio.class];return @"CoreAudio";}
    if (playerType == AVAudioEngineType){[WPlayer setAudioPlayer:WAudioEngine.class];return @"AVAudioEngine";}
    if (playerType == AVPlayerType)     {[WPlayer setAudioPlayer:WAVPlayer.class];return @"AVPlayer";}
    
    return @"None";
}

- (BOOL)canEQ {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    return type == CoreAudioType || type == AVAudioEngineType;
}

id AudioPlayerInstance(void) {
    return [AudioPlayer instance];
}

Class PlayerClass(void) {
    return AudioPlayer;
}

+ (Class)setAudioPlayer:(Class)class {
    return AudioPlayer = class;
}

+ (BOOL)isFinish:(BOOL)isProduct :(float)duration {
    return [AudioPlayer isFinish:isProduct :duration];
}

CGFloat PreSongPacketCnt(int total) {
    return [AudioPlayer PreSongPacketCnt:total];
}

CGFloat GetTimeFromPacket(CGFloat time) {
    return [AudioPlayer GetTimeFromPacket:time];
}

CGFloat GetTotalTime(BOOL isProduct,CGFloat fileDuration) {
    return [AudioPlayer GetTotalTime:isProduct :fileDuration];
}

CGFloat GetDownloadSecFromTotalSec(CGFloat total) {
    return [WCoreAudio GetDownloadSecFromTotalSec:total];
}

CGFloat GetCurrentTime(CGFloat total) {
    return [AudioPlayer GetCurrentTime:total];
}

CGFloat GetProcessorViewValue(CGFloat total) {
    return [AudioPlayer GetProcessorViewValue:total];
}

+ (NSString *)streamingUrl {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [WCoreAudio instance].streamingUrl;
    if (type == AVAudioEngineType)  return [WAudioEngine instance].streamingUrl;
    if (type == AVPlayerType)       return [WAVPlayer instance].streamingUrl;
    return [WCoreAudio instance].streamingUrl;
}

+ (enum PlayerState)playState {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [WCoreAudio instance].state;
    if (type == AVAudioEngineType)  return [WAudioEngine instance].state;
    if (type == AVPlayerType)       return [WAVPlayer instance].state;
    return [WCoreAudio instance].state;
}

+ (void)pause {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] pause];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] pause];
    if (type == AVPlayerType)       return [[WAVPlayer instance] pause];
}

+ (void)songStop {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] stop];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] stop];
    if (type == AVPlayerType)       return [[WAVPlayer instance] stop];
}

+ (void)moveToSeek:(CGFloat)seekPacket {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] moveToSeek:seekPacket];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] moveToSeek:seekPacket];
    if (type == AVPlayerType)       return [[WAVPlayer instance] moveToSeek:seekPacket];
}

+ (void)addTarget:(id)target {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] addObserverTarget:target];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] addObserverTarget:target];
    if (type == AVPlayerType)       return [[WAVPlayer instance] addObserverTarget:target];
}

+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] playWithUrl:url header:header body:body effectOption:option completionHandler:completionHandler];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] playWithUrl:url header:header body:body completionHandler:completionHandler];
    if (type == AVPlayerType)       return [[WAVPlayer instance] playWithUrl:url muteInfo:muteInfo header:header body:body completionHandler:completionHandler];
    return NO;
}

+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] playWithUrl:url effectOption:option completionHandler:completionHandler];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] playWithUrl:url completionHandler:completionHandler];
    if (type == AVPlayerType)       return [[WAVPlayer instance] playWithUrl:url muteInfo:muteInfo completionHandler:completionHandler];
    return NO;
}

+ (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)muteInfo effectOption:(AUEffectOption)option {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] playWithUrl:url effectOption:option];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] playWithUrl:url];
    if (type == AVPlayerType)       return [[WAVPlayer instance] playWithUrl:url muteInfo:muteInfo];
    return NO;
}

+ (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] playWithUrl:url effectOption:option];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] playWithUrl:url];
    if (type == AVPlayerType)       return [[WAVPlayer instance] playWithUrl:url];
    return NO;
}

+ (BOOL)playWithUrl:(NSString *)url {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] playWithUrl:url effectOption:0];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] playWithUrl:url];
    if (type == AVPlayerType)       return [[WAVPlayer instance] playWithUrl:url];
    return NO;
}

+ (dispatch_queue_t)player_q {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return [[WCoreAudio instance] player_q];
    if (type == AVAudioEngineType)  return [[WAudioEngine instance] player_q];
    if (type == AVPlayerType)       return [[WAVPlayer instance] player_q];
    return [[WCoreAudio instance] player_q];
}

#pragma mark - EQ
void SetUpAudioUnitEQGlobalValue(Float32 value) {
    
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType) {
        [[WCoreAudio instance] setUpAudioUnitValue:value
                               AudioEffecGroupType:(struct AudioEffecGroupType){AUNBandEQType,kAUNBandEQParam_GlobalGain}];
        return;
    }
    
    if (type == AVAudioEngineType) {
        [[WAudioEngine instance] setUpAudioUnitEQGlobalValue:value];
        return;
    }
    
    if (type == AVPlayerType) {
        return;
    }
    
}

void SetUpAudioUnitFilterValue(Float32 value, struct AudioEffecGroupType filterType) {
    
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType) {
        [[WCoreAudio instance] setUpAudioUnitValue:value
                               AudioEffecGroupType:filterType];
        return;
    }
    
    if (type == AVAudioEngineType) {
        return;
    }
    
    if (type == AVPlayerType) {
        return;
    }
    
}


void SetUpAudioUnitEQValue(Float32 value, UInt32 eQBandNum) {
    
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType) {
        [[WCoreAudio instance] setUpAudioUnitEQValue:value eQBandNum:eQBandNum AudioEffecGroupType:(struct AudioEffecGroupType){AUNBandEQType,kAUNBandEQParam_Gain}];
        return;
    }
    
    if (type == AVAudioEngineType) {
        [[WAudioEngine instance] setUpAudioUnitEQValue:value eQBandNum:eQBandNum];
        return;
    }
    
    if (type == AVPlayerType) {
        return;
    }
    
}

#pragma mark - Volume
__attribute__((overloadable)) void SoundVolume(Float64 value) {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      {[WCoreAudio soundVolume:value];return;}
    if (type == AVAudioEngineType)  {[WAudioEngine soundVolume:value];return;}
    if (type == AVPlayerType)       {[WAVPlayer soundVolume:value];return;}
}

__attribute__((overloadable)) void SoundVolume(Float64 value,BOOL isTemp) {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      {[WCoreAudio soundVolume:value :isTemp];return;}
    if (type == AVAudioEngineType)  {[WAudioEngine soundVolume:value :isTemp];return;}
    if (type == AVPlayerType)       {[WAVPlayer soundVolume:value :isTemp];return;}
}

__attribute__((overloadable)) Float32 SoundVolume(void) {
    enum AudioPlayerType type = [WPlayer instance].playerType;
    if (type == CoreAudioType)      return[WCoreAudio soundVolume];
    if (type == AVAudioEngineType)  return[WAudioEngine soundVolume];
    if (type == AVPlayerType)       return[WAVPlayer soundVolume];
    return 0;
}
@end
