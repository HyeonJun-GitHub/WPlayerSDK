//
//  CAProcessor.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 30..
//  Copyright © 2017년 Wally. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "CAConverterUnit.h"
#import "CAFilterManager.h"
#import "WPlayer.h"

/**
 재생 상태 변환에 대한 알림 (단일 모듈로 Observer를 사용하지 않고, Delegate로 연결해야합니다.)
 */
@protocol CAProcessorDelegate <NSObject>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object;

@end


/**
 리소스 파일로 노래를 재생 //
 REC : 'Local File Data' or 'Streaming Data'
 */
@interface WCoreAudio : NSObject

@property (nonatomic,assign) id<CAProcessorDelegate>delegate;

/**
 현재 오디오 처리중인지 여부
 */
@property (nonatomic,assign) enum PlayerState state;

/**
 현재 사운드 출력 여부
 */
@property (nonatomic,assign) enum SoundState    soundState;
@property (nonatomic,strong) CAParser           *parser;
@property (nonatomic,strong) CABuffer           *buffer;

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

/*
 @ func     : instanceProcessor
 @ desc     : 싱글톤
 */
+(WCoreAudio *)instance;

- (dispatch_queue_t)player_q;

- (id)initWithUrl:(NSString *)url;

- (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option;
- (BOOL)playWithUrl:(NSString *)url completionHandler:(void(^)(BOOL isError))completionHandler;
- (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler;
- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler;
- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler;

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

/**
 유닛 Value 변경
 
 @param value 값
 @param type 변경할 유닛타입
 */
-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type;


/**
 EQ Value 변경
 
 @param value 값
 @param num 변경할 밴드넘버
 @param type 변경할 유닛타입
 */
-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type;

/**
 그룹핑되어 있는 AudioUnit에 타입이 등록되어있는지 체크
 
 @param type 확인할 타입
 @return 등록여부
 */
-(bool)CheckAEGroupType:(struct AudioEffecGroupType)type;

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
@end
