//
//  GAVPlayer.h
//  AudioTest
//
//  Created by 김현준 on 2017. 7. 11..
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//##import "CAConverterUnit.h"
#import "CAFilterManager.h"
#import "WPlayer.h"

@protocol AVProcessorDelegate <NSObject>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object;

@end

@interface WAVPlayer : NSObject<AVAssetResourceLoaderDelegate> {
    
    NSTimer *playbackTimer;
}

/**
 현재 오디오 처리중인지 여부
 */
@property (nonatomic,assign) enum PlayerState state;

/**
 현재 사운드 출력 여부
 */
@property (nonatomic,assign) enum SoundState  soundState;

@property (nonatomic, assign) id<AVProcessorDelegate>delegate;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSString *streamingUrl;
@property (nonatomic, assign) Float64         totalPacketCnt;
@property (nonatomic, strong) NSMutableData *songData;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic,assign) BOOL isStreaming;
@property (strong) id timeObserverToken;
/*
 @ func     : instance
 @ desc     : 싱글톤
 */
+(WAVPlayer *)instance;

#pragma mark- As Is

- (BOOL)playWithUrl:(NSString *)url;
- (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)info;
- (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)info completionHandler:(void(^)(BOOL isError))completionHandler;
- (BOOL)playWithUrl:(NSString *)urlStr muteInfo:(NSMutableDictionary *)info header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler;
/**
 시작
 
 @param isStart 처음부터 재생여부
 */
- (void)play:(BOOL)isStart;


/**
 종료
 */
- (void)stop;


/**
 일시정지
 */
- (void)pause;
- (void)agrainPlay;


/**
 Seeking
 
 @param seekPacket 이동할 Packet
 */
- (void)moveToSeek:(CGFloat)seekPacket;

///**
// 유닛 Value 변경
//
// @param value 값
// @param type 변경할 유닛타입
// */
//-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type;
//
//
///**
// EQ Value 변경
//
// @param value 값
// @param num 변경할 밴드넘버
// @param type 변경할 유닛타입
// */
//-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type;

- (BOOL)setUpCurrentTimeTotalPacket:(Float64)totalPacket;

#pragma mark - CA Notify

-(void)addObserverTarget:(id)target;

#pragma mark - Volume

/**
 CABandEQ Gain로 소리크기를 변경합니다. 볼륨값을 메모리에 저장합니다.
 @param value 0~1
 */

+(void)soundVolume:(Float64)value;


/**
 CABandEQ Gain로 소리크기를 변경합니다.
 @param value 0~1
 @param isTemp 볼륨값 메모리에 저장여부
 */
+(void)soundVolume:(Float64)value :(BOOL)isTemp;


/**
 CABandEQ Gain로 소리크기를 가져옵니다.
 @return 볼륨값
 */
+(AudioUnitParameterValue)soundVolume;

//Float32 a = SoundVolume();

- (dispatch_queue_t)player_q;

- (void)playedItem;
- (BOOL)isCheckPlayed;
@end
