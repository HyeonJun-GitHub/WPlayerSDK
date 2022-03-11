//
//  ALProcessor.m
//  KTmPlayer
//
//  Created by 김현준 on 2017. 7. 21..
//  Copyright © 2017년 wally. All rights reserved.
//

#import "WOpenAL.h"
#import "CAUtils.h"
#import <AudioToolbox/AudioToolbox.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

typedef struct MyStreamPlayer {
    AudioStreamBasicDescription    dataFormat;
    UInt32                        bufferSizeBytes;
    SInt64                        fileLengthFrames;
    SInt64                        totalFramesRead;
    ALuint                        sources[1];
    // ALuint                        buffers[BUFFER_COUNT];
    ExtAudioFileRef                extAudioFile;
} MyStreamPlayer;

@implementation WOpenAL {
    MyStreamPlayer player;
    ALCdevice* _alDevice;
    ALCcontext* _alContext;
    ALuint buffers[3];
    NSTimer *playTimer;
    float time;
}

#define ORBIT_SPEED 1
#define BUFFER_DURATION_SECONDS	1.0
#define BUFFER_COUNT 3
#define RUN_TIME 60.0

OSStatus setUpExtAudioFile (MyStreamPlayer* player,NSURL *path);

-(void)updateSourceLocation:(ALfloat)x :(ALfloat)y :(ALfloat)z {
    //    double theta = fmod (CFAbsoluteTimeGetCurrent() * ORBIT_SPEED, M_PI * 2);
    //    printf ("%f\n", theta);
    printf ("x=%f, y=%f, z=%f\n", x, y, z);
    self.x = x;
    self.y = y;
    self.z = z;
    alSource3f(player.sources[0], AL_POSITION, self.x, self.y, self.z);
}


/**
 @brief 파일 포멧
 */
OSStatus setUpExtAudioFile (MyStreamPlayer* player,NSURL *url) {
    
    CFURLRef inputFileURL = CFBridgingRetain(url);
    //mono : mChannelsPerFrame 1임
    memset(&player->dataFormat, 0, sizeof(player->dataFormat));
    player->dataFormat.mFormatID = kAudioFormatLinearPCM;
    player->dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    player->dataFormat.mSampleRate = 44100.0;
    player->dataFormat.mChannelsPerFrame = 1;
    player->dataFormat.mFramesPerPacket = 1;
    player->dataFormat.mBitsPerChannel = 16;
    player->dataFormat.mBytesPerFrame = 2;
    player->dataFormat.mBytesPerPacket = 2;
    
    CheckError (ExtAudioFileOpenURL(inputFileURL, &player->extAudioFile),
                "파일 오픈 실패");
    CFRelease(inputFileURL);
    CheckError(ExtAudioFileSetProperty(player->extAudioFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       sizeof (AudioStreamBasicDescription),
                                       &player->dataFormat),
               "파일 포멧 실패");
    
    UInt32 propSize = sizeof (player->fileLengthFrames);
    ExtAudioFileGetProperty(player->extAudioFile,
                            kExtAudioFileProperty_FileLengthFrames,
                            &propSize,
                            &player->fileLengthFrames);
    
    player->bufferSizeBytes = BUFFER_DURATION_SECONDS *
    player->dataFormat.mSampleRate *
    player->dataFormat.mBytesPerFrame;
    
    return noErr;
}

/**
 @brief 오디오 셈플을 Buffer에 채워줍니다.
 */
-(void)fillALBuffer:(MyStreamPlayer* )player alBuffer:(ALuint)alBuffer {
    AudioBufferList *bufferList;
    UInt32 ablSize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * 1); // 1 channel
    bufferList = malloc (ablSize);
    
    UInt16 *sampleBuffer = malloc(sizeof(UInt16) * player->bufferSizeBytes);
    bufferList->mNumberBuffers = 1;
    bufferList->mBuffers[0].mNumberChannels = 1;
    bufferList->mBuffers[0].mDataByteSize = player->bufferSizeBytes;
    bufferList->mBuffers[0].mData = sampleBuffer;
    
    UInt32 framesReadIntoBuffer = 0;
    do {
        UInt32 framesRead = (UInt32)player->fileLengthFrames - framesReadIntoBuffer;
        bufferList->mBuffers[0].mData = sampleBuffer + (framesReadIntoBuffer * (sizeof(UInt16)));
        CheckError(ExtAudioFileRead(player->extAudioFile,
                                    &framesRead,
                                    bufferList),
                   "오디오 파일 읽어오기 실패");
        framesReadIntoBuffer += framesRead;
        player->totalFramesRead += framesRead;
        printf ("현재 %d frames\n", framesRead);
        if (framesRead == 0) {
            [self stop];
        }
    } while (framesReadIntoBuffer < (player->bufferSizeBytes / sizeof(UInt16)));
    
    alBufferData(alBuffer,
                 AL_FORMAT_MONO16,
                 sampleBuffer,
                 player->bufferSizeBytes,
                 player->dataFormat.mSampleRate);
    
    free (bufferList);
    free (sampleBuffer);
}

/**
 가공된 데이타를 버퍼에 채움 (이전에 버퍼에 채워진 데이타는
 */
-(void)refillALBuffers:(MyStreamPlayer*)player {
    ALint processed;
    alGetSourcei (player->sources[0], AL_BUFFERS_PROCESSED, &processed);
    CheckALError ("버퍼 못가져옴");
    
    while (processed > 0) {
        ALuint freeBuffer;
        alSourceUnqueueBuffers(player->sources[0], 1, &freeBuffer);
        CheckALError("couldn't unqueue buffer");
        printf ("refilling buffer %d\n", freeBuffer);
        [self fillALBuffer:player alBuffer:freeBuffer];
        alSourceQueueBuffers(player->sources[0], 1, &freeBuffer);
        CheckALError ("couldn't queue refilled buffer");
        printf ("re-queued buffer %d\n", freeBuffer);
        processed--;
    }
    
}

#pragma mark main

/**
 Start
 */
- (void)ALProcessing:(NSURL *)openUrl {
    
    CheckError(setUpExtAudioFile(&player,openUrl),
               "Couldn't open ExtAudioFile") ;
    
    //디바이스,컨텍스트를 생성합니다.
    _alDevice = alcOpenDevice(NULL);
    _alContext = alcCreateContext(_alDevice, 0);
    alcMakeContextCurrent (_alContext);
    
    //OpenAl 버퍼 생성
    alGenBuffers(BUFFER_COUNT, buffers);
    
    for (int i=0; i<BUFFER_COUNT; i++) {
        [self fillALBuffer:&player alBuffer:buffers[i]];
    }
    
    //동시에 출력가능한 사운드 수(채널)
    alGenSources(1, player.sources);
    alSourcef(player.sources[0], AL_GAIN, AL_MAX_GAIN);
    
    //좌표 0으로 초기화
    [self updateSourceLocation:0 :0 :0];
    
    alSourceQueueBuffers(player.sources[0],
                         BUFFER_COUNT,
                         buffers);
    
    //포지션 초기화
    alListener3f (AL_POSITION, 0.0, 0.0, 0.0);
    
    [self playAL];
    
    if (playTimer) {
        [playTimer invalidate];
        playTimer = nil;
    }
    playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playingAL) userInfo:nil repeats:YES];
}

//업데이트
-(void)playingAL {
    //사운드 위치 업데이트
    [self updateSourceLocation:self.x :self.y :self.z];
    
    //사운드 위치 적용된 버퍼로 변경
    [self refillALBuffers:&player];
}

- (void)playAL {
    self.isPlaying = YES;
    alSourcePlayv (1, player.sources);
}

- (void)pauseAL {
    self.isPlaying = NO;
    alSourcePausev (1, player.sources);
}

- (void)stop {
    @try {
        alSourceStop(player.sources[0]);
        alDeleteSources(1, player.sources);
        alDeleteBuffers(BUFFER_COUNT, buffers);
        alcDestroyContext(_alContext);
        alcCloseDevice(_alDevice);
    }@catch (NSException *exception) {
        
    }
}

@end

@implementation WOpenAL(Util)

void CheckALError (const char *operation) {
    ALenum alErr = alGetError();
    if (alErr == AL_NO_ERROR) return;
    char *errFormat = NULL;
    switch (alErr) {
        case AL_INVALID_NAME: errFormat = "OpenAL Error: %s (AL_INVALID_NAME)"; break;
        case AL_INVALID_VALUE:  errFormat = "OpenAL Error: %s (AL_INVALID_VALUE)"; break;
        case AL_INVALID_ENUM:  errFormat = "OpenAL Error: %s (AL_INVALID_ENUM)"; break;
        case AL_INVALID_OPERATION: errFormat = "OpenAL Error: %s (AL_INVALID_OPERATION)"; break;
        case AL_OUT_OF_MEMORY: errFormat = "OpenAL Error: %s (AL_OUT_OF_MEMORY)"; break;
        default: errFormat = "OpenAL Error: %s (unknown error code)"; break;
    }
    fprintf (stderr, errFormat, operation);
    //    exit(1);
    
}

@end
#pragma GCC diagnostic pop
