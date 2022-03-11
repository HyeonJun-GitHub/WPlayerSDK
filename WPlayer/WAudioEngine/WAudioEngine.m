//
//  GAEngine.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 30..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "WAudioEngine.h"
#include "CAUtils.h"
#import "CADownload.h"
#import "CADebug.h"
#import "CARemoteIO.h"
#import <AVFoundation/AVFoundation.h>
#define USE_SOURCE_NODE 1
#define SOUND_MAX_DEFAULT_VOLUME 1 //MainMixerVolume : 1

static Float64 VOLUME_DEFAULT = 0.5;
#if !SOUND_MAX_DEFAULT_VOLUME
static Float64 VOLUME_MIN = 96;
static Float64 VOLUME_MUTE = -96;
static Float64 VOLUME_MIN = 60;//(VOLUME_MIN-VOLUME_MAX)/2
static Float64 VOLUME_MAX = 24;
static Float64 CONTROL_VOLUME_MIN = 24;
#endif
static Float64 SWEET_VOLUME_FRAME = 100;
static Float64 PREVIOUS_PECKET = 5;

@interface WAudioEngine()<CAParserDelegate,CADownloadDelegate,NSURLSessionDelegate,NSURLSessionTaskDelegate>

@property (nonatomic,assign) Float64         sweetVolumeValue;
@property (nonatomic,assign) id              notificationTarget;
@property (nonatomic,strong) CAConverter     *converter;
@property (nonatomic,strong) CAFilterManager *filterManager;
@property (nonatomic,strong) NSURLSessionDataTask *task;
@property (nonatomic,strong) NSTimer         *muteTimer;
@end

@implementation WAudioEngine

SINGLETON(WAudioEngine, instance);
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
        //스피커 변경 노티 등록
        [self registeredNotify];
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

- (BOOL)setUpFilePath:(NSString *)path {
    
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAudioFile *localFile = [[AVAudioFile alloc] initForReading:url error:&error];
    
    if (localFile == nil) {
        NSString *LOG = [NSString stringWithFormat:@"[AVAudioFile Error] %@", error];
        NSLog(@"LOG_TEMP : %@", LOG);
        return YES;
    }
    
    return NO;
}

#pragma mark - Control

- (BOOL)playWithUrl:(NSString *)url {
    return [self playWithUrl:url completionHandler:^(BOOL isError) {}];
}

- (BOOL)playWithUrl:(NSString *)url completionHandler:(void(^)(BOOL isError))completionHandler {
    return [self playWithUrl:url header:@{} body:@{} completionHandler:completionHandler];
}

- (BOOL)playWithUrl:(NSString *)url header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler {
    
    if (!url) {
        return NO;
    }
    
    if (!url.length) {
        return NO;
    }
    
    NSRange r = [url rangeOfString:@"http://"];
    NSRange r_ssl = [url rangeOfString:@"https://"];
    _isStreaming = r.location != NSNotFound || r_ssl.location != NSNotFound;
    
    if (_isStreaming) {
        [self streamingPlayWithUrl:url header:header body:body];
        return YES;
    }
    
    self.destinationFilePath = url;
    self.fileStartFrame = 0;
    [self play:YES];
    return self.state != STOP;
}


- (void)play:(BOOL)isStart {
    
    //    NSLog(@"디바이스 ID : %@",[self getDeviceId]);
    
    [self initSubClass];
    
    if(!_isStreaming) {
        //파일 정보
        BOOL isErr = [self setUpFilePath:_destinationFilePath];
        
        if (isErr) {
            [self stop];
            if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
                [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(START)];
            }
            return;
        }
    }
    
    //AudioProcessor 시작..
    _state = START;
    
    //그래프 생성
    [self createMyEngine:_engine];
    
    if (self.state == STOP) {
        [self initSubClass];
        return;
    }
    
    if (_isStreaming) {
        return;
    }
    
    //로컬 파일이면 강제로 데이터 셋
    NSData *data = [NSData dataWithContentsOfFile:_destinationFilePath];
    _downloadingSize = 100;
    if(_parser)[_parser parseData:data];
    
    self.state = PLAYING;
    NSError *err = nil;
    [_engine startAndReturnError:&err];
    if (err) {
        NSLog(@"err : %@",err);
    }
    SoundVolume(self.volumeValue);
}

- (void)startPlayer {
    self.state = PLAYING;
    NSError *err = nil;
    [self.engine startAndReturnError:&err];
    
    self.soundState = CASoundStateOutPut;
    SoundVolume(_volumeValue);
    dispatch_async(self.player_q, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerStateNotify object:nil userInfo:@{@"STATE":@(PLAYING)}];
    });
}

- (void)stop {
    NSLog(@"[GAEngine STOP]");
    @try {
        self.sampleFrameSavedPosition = 0;
        _destinationFilePath = nil;
        self.state = STOP;
        
        @try {
            CASuccess(CheckError(AudioOutputUnitStop(_engine.outputNode.audioUnit),"AudioOutputUnitStop"));
            
            if(_sourceNode)[_engine disconnectNodeOutput:_sourceNode];
            if(_eqNode)[_engine disconnectNodeOutput:_eqNode];
        } @catch (NSException *exception) {
            NSLog(@"[GAEngine Stop] : disconnectNode,AudioOutputUnitStop Error!");
        } @finally {
            [_engine reset];
        }
        
        if (_task) {
            [_task cancel];
            _task = nil;
        }
        
        [self->_converter stop];
        
        if (_parser) {
            [_parser parseClose];
            self->_parser = NULL;
        }
        
        [_buffer initPackets];
        _buffer = NULL;
        _streamingUrl = nil;
    } @catch (NSException *exception) {
        
    } @finally {
        [self removeObserver];
    }
}

- (void)pause {
    
    if (self.state == PLAYING && _engine.isRunning) {
        self.state = PAUSE;
        
        [_engine pause];
        return;
    }
    
    if (self.state == PAUSE) {
        self.state = PLAYING;
        
        [_engine startAndReturnError:nil];
        return;
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

#pragma mark - AudioEngine

- (void)registeredUnitNode {
    AVAudioMixerNode *mainMixer = _engine.mainMixerNode;
    AVAudioOutputNode *outputNode = _engine.outputNode;
    
    [self createEqBand];
    
    [_engine connect:mainMixer to:outputNode format:_inputFormat];
    //    [_engine connect:_eqNode to:outputNode format:_inputFormat];
}

- (void)registeredNode {
    AVAudioMixerNode *mainMixer = _engine.mainMixerNode;
    AVAudioOutputNode *outputNode = _engine.outputNode;
    
    [self createEqBand];
    
    [_engine connect:_sourceNode to:_eqNode format:_inputFormat];
    [_engine connect:_eqNode to:mainMixer format:_inputFormat];
    [_engine connect:mainMixer to:outputNode format:nil];
}

-(void)createMyEngine:(AVAudioEngine *)engine
{
    if (_engine)[self cancelMyEngine:_engine];
    
    //AudioEngine 생성..
    _engine = [AVAudioEngine new];
    
    //콜백 등록
    if(![self registeredListener]) {
        NSLog(@"리스터 등록 실패!");
        return;
    }
    
    //노드 등록 및 연결
#if USE_SOURCE_NODE
    //콜러 방식을 제어합니다.
    [self registeredNode];
#else
    [self registeredUnitNode];
#endif
}

- (void)cancelMyEngine:(AVAudioEngine *)engine {
    [self.engine disconnectNodeOutput:_sourceNode];
    [self.engine disconnectNodeOutput:_eqNode];
    
    [self.engine detachNode:_sourceNode];
    [self.engine detachNode:_eqNode];
    
    [self.engine stop];
}

- (void)registeredNotify {
    __weak typeof(self)THIS = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        if (!THIS.engine) {
            return;
        }
#if 0
        NSError *err = nil;
        [THIS.engine startAndReturnError:&err];
        NSLog(@"%@",err);
        return;
#else
        THIS.state = PAUSE;
        if ([THIS.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
            [THIS.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(THIS.state)];
        }
        [THIS stop];
#endif
    }];
}

//https://developer.apple.com/library/archive/qa/qa1777/_index.html 참고..
- (BOOL)registeredListener {
#if USE_SOURCE_NODE
    //콜러 방식을 제어합니다.
    return [self registeredSourceNodeRender];
#else
    [self registeredUnitRender];
    return YES;
#endif
}

- (BOOL)registeredSourceNodeRender {
    
    UInt32 maxFPS = 4096;
    
    AudioUnit audioUnit = _engine.outputNode.audioUnit;
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    
    AVAudioFormat *outPutFormat = [_engine.outputNode inputFormatForBus:0];
    _inputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:outPutFormat.sampleRate channels:2 interleaved:outPutFormat.isInterleaved];
    
    __weak typeof(self)THIS = self;
    if (@available(macOS 10.15, *)) {
        _sourceNode = [[AVAudioSourceNode alloc] initWithRenderBlock:^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
            OSStatus status = [THIS requestNumberOfFrames:frameCount ioData:outputData busNumber:0];
            return status;
        }];
        [_engine attachNode:_sourceNode];
        
        return YES;
    }
    
    return NO;
}

- (void)registeredUnitRender {
    AudioUnit audioUnit = _engine.inputNode.audioUnit;
    
    UInt32 maxFPS = 4096;
//    double sampleRate = 44100;//((AVAudioFormat *)[_engine.outputNode outputFormatForBus:0]).sampleRate;
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Input, 0,&maxFPS, sizeof(maxFPS));
    
    //    AVAudioFormat *outPutFormat = [_engine.outputNode outputFormatForBus:0];
    _inputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100 channels:1 interleaved:NO];
    
    //PCM..
    [self setUpPCMFormat:CACreatePCM(CAAudioFileTypeFloat32) toUnit:audioUnit];
    
    //Unit CallBack..
    AURenderCallbackStruct callbackStruct = {
        .inputProcRefCon = (__bridge void *)(self),
        .inputProc = UnitRenderCallback
    };
    
    OSStatus status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct));
    CASuccess(CheckError(status,"AURenderCallbackStruct kAudioUnitProperty_SetRenderCallback"));
}


- (void)setUpPCMFormat:(AudioStreamBasicDescription)asbd toUnit:(AudioUnit)unit {
    
    UInt32 sizeASBD = sizeof(AudioStreamBasicDescription);
    AudioStreamBasicDescription ioASBDin;
    AudioStreamBasicDescription ioASBDout;
    AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &ioASBDin, &sizeASBD);
    AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &ioASBDout, &sizeASBD);
    
    
    AudioUnitSetProperty(unit,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Input,0,& ioASBDin,sizeof(AudioStreamBasicDescription));
    AudioUnitSetProperty(unit,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Output,0,&asbd,sizeof(AudioStreamBasicDescription));
    
    //    AudioStreamBasicDescription destFormat = asbd;
    //    UInt32 size = sizeof(AudioStreamBasicDescription);
    //    AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &destFormat, size);
    //    AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &destFormat, size);
}

#pragma mark - Proc

OSStatus RenderSineWave(UInt32 inNumberFrames,AudioBufferList *ioData) {
    float SAMPLE_RATE =  48000;
    float TONE_FREQUENCY =  440;
    float M_TAU =  2.0 * M_PI;
    
    static float theta;
    
    Float32 *left = (Float32 *)ioData->mBuffers[0].mData;
    for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
        left[frame] = (Float32)(sin(theta) * 32767.0f);
        theta += M_TAU * TONE_FREQUENCY / SAMPLE_RATE;
        if (theta > M_TAU) {
            theta -= M_TAU;
        }
    }
    
    // Copy left channel to right channel
    memcpy(ioData->mBuffers[1].mData, left, ioData->mBuffers[1].mDataByteSize);
    
    return noErr;
}

static OSStatus UnitRenderCallback(void *userData, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    WAudioEngine *THIS = (__bridge WAudioEngine *)userData;
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
    _converter = [[CAConverter alloc] initWithSourceFormat:inDescription destFormat:*_inputFormat.streamDescription];
    
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
    UInt32 STEP = 0;
    @try {
        STEP = 1;
        if (self.state != STOP && CheckBuffer(self.buffer)) {
            {
                STEP++;
                CGFloat totalPacket = (CGFloat)self.buffer.packetWriteIndex;
                CGFloat readPacket = (CGFloat)self.buffer.packetReadIndex;
                self.totalPacketCnt = totalPacket;
                self.currentPacketIdx = readPacket;
                self.currentTime = self.currentPacketIdx / self.totalPacketCnt;
            }
            
            STEP++;
            status = [_converter requestNumberOfFrames:inNumberOfFrames ioData:inIoData busNumber:inBusNumber buffer:self.buffer];
            return status;
        }
        
        if ([CADownload instance].state == DOWNLOAD_ING) {
            STEP = 10;
            status = [_converter requestNumberOfFrames:inNumberOfFrames ioData:inIoData busNumber:inBusNumber buffer:self.buffer];
            return status;
        }
        
        STEP = 100;
        [self initTimeStampWithFrame];
        _engine.mainMixerNode.outputVolume = 0;
        [_engine reset];
        
        STEP++;
        if (self.state == STOP && [CADownload instance].state != DOWNLOAD_COMPLETE) {
            STEP++;
            return status;
        }
        
        STEP++;
        self.state = STOP;
        if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
            [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(self.state)];
        }
        
    } @catch (NSException *exception) {
        /*
         STEP = 1;   //곡 재생중....
         STEP = 10;  //다운로드딩....
         STEP = 100; //곡 종료....
         */
        NSString *LOG = [NSString stringWithFormat:@"[ThreadIO] Buffer Rendering Crashed!! STEP : %d",STEP];
        NSLog(@"LOG_TEMP : %@", LOG);
    }
    
    return status;
}

+ (void)removeVoiceIoData:(AudioBufferList  *)inIoData {
    Float32 *data = inIoData->mBuffers[0].mData;
    for (int i = 0; i < inIoData->mBuffers[0].mDataByteSize; i += 2) {
        Float32 left = data[i];
        Float32 right = data[i + 1];
        Float32 new = left - right;
        data[i] = new;
        data[i+1] = new;
    }
    inIoData->mBuffers[0].mData = data;
}

#pragma mark - Networking

- (void)streamingPlayWithUrl:(NSString *)url header:(NSDictionary *)headerField body:(NSDictionary *)body {
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
        NSError *err = nil;
        [_engine startAndReturnError:&err];
        if (err) {
            NSLog(@"err : %@",err);
        }
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
}

#pragma mark - Util

- (BOOL)setUpCurrentTimeTotalPacket:(Float64)totalPacket {
    
    [self sweeteSound:totalPacket];
    
    if (self.currentPacketIdx > totalPacket - PREVIOUS_PECKET && totalPacket != 0) {
        self.state = STOP;
        return YES;
    }
    
    return NO;
}

- (void)agrainPlay {
    
    
}

#pragma mark - Mute

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
    
    [WAudioEngine changeToVolumeGain:self :0 :YES];
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

+(void)changeToVolumeGain:(WAudioEngine *)gAEngine :(Float64)originVolumeValue :(BOOL)isTemp {
    
#if SOUND_MAX_DEFAULT_VOLUME
    gAEngine.engine.mainMixerNode.outputVolume = originVolumeValue;
#else
    BOOL isPositive = originVolumeValue > 0.5;
    Float64 addValue = isPositive?VOLUME_MAX:isTemp?VOLUME_MIN:CONTROL_VOLUME_MIN;
    originVolumeValue = (originVolumeValue -0.5) / 0.5 * addValue;
    if (originVolumeValue == -(addValue)) {
        originVolumeValue = VOLUME_MUTE;
    }
    
    gAEngine.eqNode.globalGain = originVolumeValue;
#endif
}

+(void)soundVolume:(Float64)value {
    WAudioEngine *gAEngine = [WAudioEngine instance];
    gAEngine.volumeValue = value;
    [WAudioEngine changeToVolumeGain:gAEngine :value :NO];
}

+(void)soundVolume:(Float64)value :(BOOL)isTemp {
    WAudioEngine *gAEngine = [WAudioEngine instance];
    [WAudioEngine changeToVolumeGain:gAEngine :value :isTemp];
}

+(AudioUnitParameterValue)soundVolume {
    WAudioEngine *gAEngine = [WAudioEngine instance];
    return gAEngine.eqNode.globalGain;
}


#pragma mark - EQ

-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num {
#if DEBUG
    NSLog(@"%s Num : %@ Value : %@",__func__,@(num),@(value));
#endif
    AVAudioUnitEQFilterParameters *param = _eqNode.bands[num];
    param.gain = value;
}

-(void)setUpAudioUnitEQGlobalValue:(AudioUnitParameterValue)value {
#if DEBUG
    NSLog(@"%s",__func__);
#endif
    _eqNode.globalGain = value;
}

- (void)createEqBand {
    NSArray <NSNumber *>*eqFrequencies = @[@63.f,   @125.f,  @250.f,  @500.f,   @1000.f,  @2000.f,
                                           @4000.f,  @8000.f, @12500.f, @16000.f];
    
    _eqNode = [[AVAudioUnitEQ alloc] initWithNumberOfBands:eqFrequencies.count];
    [_engine attachNode:_eqNode];
    
    for (int i = 0; i < eqFrequencies.count-1; i++) {
        AVAudioUnitEQFilterParameters *param = _eqNode.bands[i];
        param.filterType = AVAudioUnitEQFilterTypeParametric;
        param.frequency = eqFrequencies[i].floatValue;
        param.bandwidth = 1;
        param.gain = 0;
        param.bypass = NO;
    }
}

@end
