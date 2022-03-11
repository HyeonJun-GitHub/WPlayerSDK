//
//  CAProcessor.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 30..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "WCoreAudio.h"
#include "CAUtils.h"
#import "CADownload.h"
#import "CADebug.h"
#import "CARemoteIO.h"

#define SOUND_MAX_DEFAULT_VOLUME 1 //MAX가 볼륨 기준값

static Float64 VOLUME_DEFAULT = 0.5;
static Float64 VOLUME_MUTE = -96;
#if SOUND_MAX_DEFAULT_VOLUME
static Float64 VOLUME_MIN = 96;
#else
static Float64 VOLUME_MIN = 60;//(VOLUME_MIN-VOLUME_MAX)/2
static Float64 VOLUME_MAX = 24;
#endif
static Float64 CONTROL_VOLUME_MIN = 24;
static Float64 SWEET_VOLUME_FRAME = 100;
static Float64 PREVIOUS_PECKET = 5;

AUEffectOption EffectOptions() {
#if MIX_EFFECT
    return AUEffectOptionNBandEQ | AUEffectOptionMixer;
#else
    return AUEffectOptionPitch | AUEffectOptionNBandEQ;
#endif
}

/**
 EQ Gain
 */
struct AudioEffecGroupType EQGainType = {AUNBandEQType,kAUNBandEQParam_Gain};

/**
 볼륨 Gain
 */
struct AudioEffecGroupType EQVolumeGainType = {AUNBandEQType,kAUNBandEQParam_GlobalGain};

/**
 믹서노드를 활용하여, 마스터볼륨으로 사용
 */
struct AudioEffecGroupType MixerVolumeGainType = {AUMixerType,kMultiChannelMixerParam_Volume};

@interface WCoreAudio()<CAParserDelegate,CADownloadDelegate,NSURLSessionDelegate,NSURLSessionTaskDelegate>

@property (nonatomic,assign) Float64         sweetVolumeValue;
@property (nonatomic,assign) id              notificationTarget;
@property (nonatomic,strong) CAConverter     *converter;
@property (nonatomic,assign) CAAUGraphPlayer graphPlayer;
@property (nonatomic,strong) CAFilterManager *filterManager;
@property (nonatomic,strong) NSURLSessionDataTask *task;
@property (nonatomic,strong) NSTimer         *muteTimer;
@property (nonatomic,assign) AUEffectOption  effectOptions;
@end

@implementation WCoreAudio

SINGLETON(WCoreAudio, instance);
@synthesize isStreaming = _isStreaming;
@synthesize parser = _parser;
@synthesize destinationFilePath = _destinationFilePath;
@synthesize streamingUrl = _streamingUrl;
@synthesize fileStartFrame = _fileStartFrame;

#pragma mark - Init

/**
 플레이어 큐
 */
- (dispatch_queue_t)player_q {
#if 0
    static dispatch_queue_t player_q;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player_q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create("com.player.playQueue", DISPATCH_QUEUE_SERIAL);
    });
    return player_q;
#else
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
#endif
}

-(id)init {
    self = [super init];
    
    if (self) {
        self.volumeValue = VOLUME_DEFAULT;
        self.state = STOP;
        [self initSubClass];
    }
    
    return self;
}

- (id)initWithUrl:(NSString *)url {
    self = [self init];
    if (self) {
        self.streamingUrl = url;
    }
    return self;
}

- (void)initTimeStampWithFrame {
    self.fileStartFrame = 0;
    self.currentPacketIdx = 0;
    self.currentTime = 0;
}

- (void)initSubClass {
    
    _parser = [[CAParser alloc] initWithType:kAudioFileMP3Type];
    //    parser.typeID = ;//kAudioFileM4AType;
    _parser.delegate = self;
    
    self.buffer = [[CABuffer alloc] init];
    //    self.buffer.delegate = self;
    
    self.currentTime = 0;
    self.currentPacketIdx = 0;
    self.totalPacketCnt = 0;
}

-(void)addObserverTarget:(id)target {
    
    [self removeObserver];
    
    self.delegate = target;
    
    @try {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caProcessNotificationStatus:) name:PlayerStateNotify object:@(self.state)];
        
    }@catch (NSException *exception) {
        
    }
}

- (void)removeObserver {
    
    if (!_delegate) {
        return;
    }
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.delegate = nil;
    } @catch (NSException *exception) {
        
    }
}


#pragma mark - CA Notify

- (void)caProcessNotificationStatus:(NSNotification *)center {
    
    if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
        [self.delegate observeValueForKeyPath:center.name ofObject:center.object];
    }
}


#pragma mark - FileInfo From Path

CFURLRef CreateURLFromVolumeIDandDirectoryID(dev_t volumeID, SInt32 directoryID)
{
    CFStringRef thePath = CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
                                                   CFSTR("/.vol/%d/%d"), volumeID, (int) directoryID);
    
    CFURLRef theURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, thePath,
                                                    kCFURLPOSIXPathStyle, false);
    CFRelease(thePath);
    return theURL;
}

- (BOOL)setUpFilePath:(NSString *)path Player:(CAAUGraphPlayer *)player {
    
    if (!path.length) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Control

- (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option {
    return [self playWithUrl:url effectOption:option completionHandler:nil];
}

- (BOOL)playWithUrl:(NSString *)url completionHandler:(void(^)(BOOL isError))completionHandler {
    return [self playWithUrl:url effectOption:AUEffectOptionNone completionHandler:nil];
}

- (BOOL)playWithUrl:(NSString *)url effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler {
    return [self playWithUrl:url header:nil body:nil effectOption:option completionHandler:completionHandler];
}

- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler {
    return [self playWithUrl:url header:header body:body effectOption:AUEffectOptionNone completionHandler:completionHandler];
}

- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body effectOption:(AUEffectOption)option completionHandler:(void(^)(BOOL isError))completionHandler {
    
    if (!url) {
        return NO;
    }
    
    if (!url.length) {
        return NO;
    }
    
    NSRange r = [url rangeOfString:@"http://"];
    NSRange r_ssl = [url rangeOfString:@"https://"];
    _isStreaming = r.location != NSNotFound || r_ssl.location != NSNotFound;
    
    _effectOptions = option;
    
    if (_isStreaming) {
        [self streamingPlayWithUrl:url headerField:header body:body];
        return YES;
    }
    
    self.destinationFilePath = url;
    self.fileStartFrame = 0;
    [self play:YES];
    return self.state != STOP;
}

- (void)play:(BOOL)isStart {
    
    CAAUGraphPlayer player = {0};
    
    [self initSubClass];
    
    if(!_isStreaming) {
        //파일 정보
        BOOL isErr = [self setUpFilePath:_destinationFilePath Player:&player];
        
        if (isErr) {
            [self stop];
            if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
                [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(START)];
            }
            return;
        }
    }
    
    _state = START;
    
    //그래프 생성
    [self createMyAUGraph:&player];
    
    _graphPlayer = player;
    
    if (self.state == STOP) {
        [self initSubClass];
        return;
    }
    
    if (_isStreaming) {
        return;
    }
    
    //로컬 파일이면 강제로 데이터 셋
    NSData *data = [NSData dataWithContentsOfFile:_destinationFilePath];
    if(_parser)[_parser parseData:data];
    [self startPlayer];
}

- (void)startPlayer {
    self.state = PLAYING;
    
    CASuccess(CheckError(AUGraphStart(_graphPlayer.graph),"AUGraphStart"));
    CASuccess(CheckError(AudioOutputUnitStart(_graphPlayer.inPutUnit),"AudioOutputUnitStart"));
    
    self.soundState = CASoundStateOutPut;
    SoundVolume(_volumeValue);
    dispatch_async(self.player_q, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerStateNotify object:nil userInfo:@{@"STATE":@(PLAYING)}];
    });
}

- (void)stop {
    [self sleep:YES];
    NSLog(@"[CAProcessor STOP]");
    @try {
        self.sampleFrameSavedPosition = 0;
        _destinationFilePath = nil;
        self.state = STOP;
        
        if (_converter) {
            [_converter stop];
            self->_converter = NULL;
        }
        
        CASuccess(CheckError(AUGraphStop(_graphPlayer.graph),"AUGraphStop"));
        CASuccess(CheckError(AudioOutputUnitStop(_graphPlayer.inPutUnit),"AudioOutputUnitStop"));
        CASuccess(CheckError(AudioUnitUninitialize(_graphPlayer.inPutUnit),"AudioUnitUninitialize"));
        CASuccess(CheckError(AudioComponentInstanceDispose(_graphPlayer.inPutUnit),"AudioComponentInstanceDispose"));
        _graphPlayer.inPutUnit = NULL;
        
        if (_graphPlayer.graph != NULL) {
            CASuccess(CheckError(DisposeAUGraph(_graphPlayer.graph),"DisposeAUGraph"));
            
            //            AUGraphUninitialize (_graphPlayer.graph);
            //            AUGraphClose(_graphPlayer.graph);
            _graphPlayer.graph = NULL;
        }
        
        if (_task) {
            [_task cancel];
            _task = nil;
        }
        //        AudioFileClose(_graphPlayer.inputFile);
        
        self.delegate = nil;
        
        if (_parser) {
            [_parser parseClose];
            self->_parser = NULL;
        }
        
        [_buffer initPackets];
        _buffer = NULL;
        self.streamingUrl = nil;
    } @catch (NSException *exception) {
        
    } @finally {
        [self removeObserver];
    }
}

- (void)pause {
    
    Boolean isRunning = false;
    AUGraphIsRunning(_graphPlayer.graph, &isRunning);
    
    if (self.state == PLAYING && isRunning) {
        [self sleep:YES];
        AUGraphStop(_graphPlayer.graph);
        self.state = PAUSE;
        return;
    }
    
    if (self.state == PAUSE) {
        [self sleep:NO];
        AUGraphStart(_graphPlayer.graph);
        self.state = PLAYING;
    }
}

- (void)moveToSeek:(CGFloat)seekPacket {
    
    Float64 scale = seekPacket;
    Float64 seek = floor(seekPacket * 100);
    Float64 downloadPacket = floor(_downloadingSize);
    BOOL isStreaming = _downloadingSize < 100 && [CADownload instance].state == DOWNLOAD_ING;
    
    if (seekPacket > 0.98) {
        return;
    }
    
    if (isStreaming && _downloadingSize - seek < 2) {
        return;
    }
    
    [self millisecondsMute];
    
    if (isStreaming) {
        scale = seek/downloadPacket;
    }
    
    SInt64 newPacketIdx = floor(scale * self.totalPacketCnt);
    [_buffer setPacketReadIndex:newPacketIdx];
}

- (BOOL)setUpCurrentTimeTotalPacket:(Float64)totalPacket {
    
    [self sweeteSound:totalPacket];
    
    if (self.currentPacketIdx > totalPacket - PREVIOUS_PECKET && totalPacket != 0) {
        self.state = STOP;
        return YES;
    }
    
    return NO;
}

- (void)agrainPlay {
    
    CASuccess(CheckError(AudioUnitSetProperty(_graphPlayer.inPutUnit,
                                              kAudioUnitProperty_ScheduleStartTimeStamp,
                                              kAudioUnitScope_Global,
                                              0,
                                              &_sampleFrameSavedPosition,
                                              sizeof(self.sampleFrameSavedPosition)),"AudioUnitSetProperty"));
}

-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type {
    [_filterManager setUpAudioUnitValue:value AudioEffecGroupType:type];
}

-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type {
    [_filterManager setUpAudioUnitEQValue:value eQBandNum:num AudioEffecGroupType:type];
}

-(AudioUnitParameterValue)getAudioUnitValueAudioEffecGroupType:(struct AudioEffecGroupType)type {
    return [_filterManager getAudioUnitValueWithAudioEffecGroupType:type];
}

#pragma mark - AUGraph

-(void)createMyAUGraph:(CAAUGraphPlayer *)player
{
    //AUGraph 생성
    CASuccess(CheckError(NewAUGraph(&player->graph),"NewAUGraph"));
    
    //AUGraph 오픈
    CASuccess(CheckError(AUGraphOpen(player->graph),"AUGraphOpen"));
    
    //입,출력
    struct CARemote remote = {
        .input = RemoteStream,
        .output = RemoteSpeaker,
    };
    InsertCARemoteIO(player,remote);
    
    //유닛등록
    [self createAudioUnits:player];
    
    //노드 연결
    AUGraphAllConnectNodeInput(_filterManager,player);
    
    //콜백 등록
    [self registeredListener:player];
    
    //AUGraph 할당 및 초기화
    CASuccess(CheckError(AUGraphInitialize(player->graph),"AUGraphInitialize"));
    CASuccess(CheckError(AudioOutputUnitStop(player->inPutUnit),"AudioOutputUnitStop"));
}

- (void)registeredListener:(CAAUGraphPlayer *)player {
    
    UInt32 numbers = 1;
    for (int i = 0; i < numbers; i++) {
        //Slice..
        UInt32 maxFPS = 4096;
        CASuccess(CheckError(AudioUnitSetProperty(player->inPutUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, i,&maxFPS, sizeof(maxFPS)),"AudioUnitSetProperty"));
        
        //PCM..
        AudioStreamBasicDescription destFormat = CACreatePCM(2,44100,CAAudioFileTypeFloat32);
        AudioUnitSetProperty(player->inPutUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &destFormat, sizeof(destFormat));
        
        //CallBack..
        AURenderCallbackStruct callbackStruct = {
            .inputProcRefCon = (__bridge void *)(self),
            .inputProc = RenderCallback
        };
        
        CASuccess(CheckError(AUGraphSetNodeInputCallback(player->graph, player->inPutNode, i, &callbackStruct),"AUGraphSetNodeInputCallback[Input]"));
    }
}

#pragma mark - AudioUnit

- (void)createAudioUnits:(CAAUGraphPlayer *)player {
    _filterManager = [[CAFilterManager alloc] init];
    [_filterManager addAUEffects:_effectOptions player:player];
}

#pragma mark - Proc


static OSStatus RenderCallback(void *userData, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    WCoreAudio *THIS = (__bridge WCoreAudio *)userData;
    OSStatus status = [THIS requestNumberOfFrames:inNumberFrames ioData:ioData busNumber:inBusNumber];
    
    return status;
}


- (void)audioStreamParser:(CAParser *)inParser didObtainStreamDescription:(AudioStreamBasicDescription *)inDescription
{
    
    NSString *LOG = [NSString stringWithFormat:@"\
                     [Open Stream to Server is Success]\n\
                     mSampleRate: %f\n\
                     mFormatID: %u\n\
                     mFormatFlags: %u\n\
                     mBytesPerPacket: %u\n\
                     mFramesPerPacket: %u\n\
                     mBytesPerFrame: %u\n\
                     mChannelsPerFrame: %u\n\
                     mBitsPerChannel: %u\n\
                     mReserved: %u\n\
                     numPacketsForTime: %f\
                     ",inDescription->mSampleRate,(unsigned int)inDescription->mFormatID,(unsigned int)inDescription->mFormatFlags,(unsigned int)inDescription->mBytesPerPacket,(unsigned int)inDescription->mFramesPerPacket,(unsigned int)inDescription->mBytesPerFrame,(unsigned int)inDescription->mChannelsPerFrame,(unsigned int)inDescription->mBitsPerChannel,(unsigned int)inDescription->mReserved,self.totalPacketCnt];
    NSLog(@"LOG_STREAM : %@",LOG);
    
    CAudioBufferListFree(_converter.renderBufferList);
    _converter = nil;
    _converter = [[CAConverter alloc] initWithSourceFormat:inDescription destFormat:CACreatePCM(2,44100,CAAudioFileTypeFloat32)];
    
    if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
        [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(START)];
        [CAConfig loadCAValue];
    }
}

- (void)audioStreamParser:(CAParser *)inParser packetData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount
{
    [self.buffer storePacketData:inBytes dataLength:inLength packetDescriptions:inPacketDescriptions packetsCount:inPacketsCount];
}

- (OSStatus)requestNumberOfFrames:(UInt32)inNumberOfFrames ioData:(AudioBufferList  *)inIoData busNumber:(UInt32)inBusNumber
{
    OSStatus status = 0;
    
    @try {
        
        if (self.state != STOP && CheckBuffer(self.buffer)) {
            {
                CGFloat totalPacket = (CGFloat)self.buffer.packetWriteIndex;
                CGFloat readPacket = (CGFloat)self.buffer.packetReadIndex;
                self.totalPacketCnt = totalPacket;
                self.currentPacketIdx = readPacket;
                self.currentTime = self.currentPacketIdx / self.totalPacketCnt;
            }
            
            status = [_converter requestNumberOfFrames:inNumberOfFrames ioData:inIoData busNumber:inBusNumber buffer:self.buffer];
            return status;
        }
        
        if ([CADownload instance].state == DOWNLOAD_ING) {
            status = [_converter requestNumberOfFrames:inNumberOfFrames ioData:inIoData busNumber:inBusNumber buffer:self.buffer];
            return status;
        }
        
        [self initTimeStampWithFrame];
        AUGraphStop(_graphPlayer.graph);
        
        if (self.state == STOP && [CADownload instance].state != DOWNLOAD_COMPLETE) {
            return status;
        }
        
        self.state = STOP;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
                [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(self.state)];
            }
        });
        
    } @catch (NSException *exception) {
        
    }
    
    return status;
}

+ (void)removeVoiceIoData:(AudioBufferList  *)inIoData {
    UInt16 *data = inIoData->mBuffers[0].mData;
    for (int i = 0; i < inIoData->mBuffers[0].mDataByteSize; i += 2) {
        UInt16 left = data[i];
        UInt16 right = data[i + 1];
        UInt16 new = left - right;
        data[i] = new;
        data[i+1] = new;
    }
    inIoData->mBuffers[0].mData = data;
}

#pragma mark - Check


- (BOOL)hasFilter {
    return [WCoreAudio instance].filterManager == NULL ? NO : YES;
}


-(bool)CheckAEGroupType:(struct AudioEffecGroupType)type {
    return CheckAUFilter(_filterManager,type);
}

#pragma mark - Networking

- (void)streamingPlayWithUrl:(NSString *)url headerField:(NSDictionary *)headerField body:(NSDictionary *)body {
    
    self.streamingUrl = url;
    _task = [[CADownload instance] streamingPlayWithUrls:@[url] target:self headerFieldInfo:headerField];
}

#pragma mark - CADownloadDelegate

- (void)didReceiveResponse:(long long)contentLength {
    self.totalDuration = contentLength;
    _downloadingSize = 0;
    [self play:YES];
}

- (void)didReceiveData:(NSData *)data currentSize:(float)size {
    
    if (self.state == STOP) {
        return;
    }
    
    _downloadingSize = size;
    if(_parser)[_parser parseData:data];
    
    if (size > 10 && self.state == START) {
        self.state = PLAYING;
        
        CASuccess(CheckError(AUGraphStart(_graphPlayer.graph),"AUGraphStart"));
        CASuccess(CheckError(AudioOutputUnitStart(_graphPlayer.inPutUnit),"AudioOutputUnitStart"));
        SoundVolume(self.volumeValue);
    }
}

- (void)didCompleteWithError:(NSError *)error {
    
    if (error) {
        if (_task) {
            [_task cancel];
            _task = nil;
        }
        
        NSString *desc = error.userInfo[NSURLErrorFailingURLStringErrorKey];
        if ([self.streamingUrl isEqual:desc]) {
            
            if (error.code == -999) {
                return;
            }
            dispatch_async(self.player_q, ^{
                [self stop];
                [[NSNotificationCenter defaultCenter] postNotificationName:PlayerStateNotify object:nil userInfo:@{@"STATE":@(ERROR)}];
            });
        }
        return;
    }
    
    if (self.state == STOP) {
        return;
    }
    
    if (self.state == START) {
        
    }
}

#pragma mark - Mute

- (void)sleep:(BOOL)isOn {
    SoundVolume(isOn?0:1,YES);
    usleep(100000);
}

- (void)stopMute:(NSTimer *)sender {
    if (_muteTimer) {
        [_muteTimer invalidate];
        _muteTimer = nil;
    }
    
    _soundState = CASoundStateOutPut;
    SoundVolume(self.volumeValue);
}

- (void)millisecondsMute {
    
    _soundState = CASoundStateMute;
    if (_muteTimer) {
        [_muteTimer invalidate];
        _muteTimer = nil;
    }
    
    ChangeToVolumeGain(self, 0, YES);
    _muteTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(stopMute:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_muteTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - Volume

- (void)sweeteSound:(Float64)totalPacket {
    float oddSec = totalPacket - self.currentPacketIdx;
    
    //SweetVolume 활성..
    if (oddSec < SWEET_VOLUME_FRAME && oddSec > 0) {
        if (_state == PLAYING) {
            _sweetVolumeValue = oddSec;
            Float64 value = (_sweetVolumeValue / SWEET_VOLUME_FRAME) * self.volumeValue;
            Float64 minValue = self.volumeValue * 0.1;
            
            if(value < minValue)value = 0;
            SoundVolume(value,YES);
        }
        return;
    }
    
    //SweetVolume 초기화..
    if (_sweetVolumeValue != 0) {
        _sweetVolumeValue = 0;
        SoundVolume(self.volumeValue);
    }
}

void ChangeToVolumeGain(WCoreAudio *processor, Float64 originVolumeValue, BOOL isTemp) {
    
#if SOUND_MAX_DEFAULT_VOLUME
    BOOL isPositive = originVolumeValue > 0.01;
    Float64 addValue = isTemp?CONTROL_VOLUME_MIN:isPositive?CONTROL_VOLUME_MIN:VOLUME_MIN;
    Float64 value = -(addValue - (originVolumeValue * addValue));
    
    //Mute..
    if (value == -CONTROL_VOLUME_MIN || processor.soundState == CASoundStateMute)value = VOLUME_MUTE;
    
    [processor setUpAudioUnitValue:value AudioEffecGroupType:EQVolumeGainType];
#else
    BOOL isPositive = originVolumeValue > 0.5;
    Float64 addValue = isPositive?VOLUME_MAX:isTemp?VOLUME_MIN:CONTROL_VOLUME_MIN;
    originVolumeValue = (originVolumeValue -0.5) / 0.5 * addValue;
    if (originVolumeValue == -(addValue)) {
        originVolumeValue = VOLUME_MUTE;
    }
    
    [processor setUpAudioUnitValue:originVolumeValue AudioEffecGroupType:EQVolumeGainType];
#endif
}

+(void)soundVolume:(Float64)value {
    WCoreAudio *caProcessor = [WCoreAudio instance];
    caProcessor.volumeValue = value;
    ChangeToVolumeGain(caProcessor, value,NO);
}

+(void)soundVolume:(Float64)value :(BOOL)isTemp {
    WCoreAudio *caProcessor = [WCoreAudio instance];
    ChangeToVolumeGain(caProcessor, value,isTemp);
}

+(AudioUnitParameterValue)soundVolume {
    WCoreAudio *caProcessor = [WCoreAudio instance];
    return [caProcessor getAudioUnitValueAudioEffecGroupType:EQVolumeGainType];
}

@end
