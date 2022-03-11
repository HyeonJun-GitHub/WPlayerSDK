//
//  GAEngine.h
//  Wally
//
//  Created by 김현준 on 06/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CAConverterUnit.h"
#import "CAFilterManager.h"
#import "WPlayer.h"
NS_ASSUME_NONNULL_BEGIN

/**
 재생 상태 변환에 대한 알림 (단일 모듈로 Observer를 사용하지 않고, Delegate로 연결해야합니다.)
 */
@protocol GAEngineDelegate <NSObject>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object;

@end

@interface WAudioEngine : NSObject

@property (nonatomic,weak) id<GAEngineDelegate>delegate;

/**
 현재 오디오 처리중인지 여부
 */
@property (nonatomic,assign) enum PlayerState state;

/**
 현재 사운드 출력 여부
 */
@property (nonatomic,assign) enum SoundState  soundState;
@property (nonatomic,strong) CAParser           *parser;
@property (nonatomic,strong) CABuffer           *buffer;

@property (nonatomic,strong) AVAudioEngine      *engine;
@property (nonatomic,strong) AVAudioUnitEQ      *eqNode;
@property (nonatomic,strong) AVAudioSourceNode  *sourceNode API_AVAILABLE(macos(10.15));
@property (nonatomic,strong) AVAudioFormat      *inputFormat;
/**
 필터 매니저 객체 생성 여부
 */
@property (nonatomic,readonly)  BOOL            hasFilter;
@property (nonatomic,assign)    Float64         downloadingSize;
@property (nonatomic,assign)    Float64         volumeValue;
@property (nonatomic,assign)    Float64         sampleFrameSavedPosition;
@property (nonatomic,assign)    Float64         totalDuration;
@property (nonatomic,assign)    Float64         totalPacketCnt;
@property (nonatomic,assign)    Float64         fileStartFrame;
@property (nonatomic,assign)    Float64         currentPacketIdx;
/**
 0~1 사이로 보여짐
 */
@property (nonatomic,assign)    Float64         currentTime;

/**
 파일 경로
 */
@property (nonatomic,strong) NSString *destinationFilePath;
@property (nonatomic,strong) NSString *streamingUrl;
@property (nonatomic,strong) dispatch_queue_t player_q;
#pragma mark - 스트리밍 테스트 , TODO : 구조 변경해야함
@property (nonatomic,assign) BOOL isStreaming;
#pragma mark - _____

+(WAudioEngine *)instance;

- (BOOL)playWithUrl:(NSString *)url;
- (BOOL)playWithUrl:(NSString *)url completionHandler:(void(^)(BOOL isError))completionHandler;
- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler;

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

-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num;
-(void)setUpAudioUnitEQGlobalValue:(AudioUnitParameterValue)value;
@end

NS_ASSUME_NONNULL_END
