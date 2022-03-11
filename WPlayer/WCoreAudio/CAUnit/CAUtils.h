//
//  CAUtils.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 15..
//  Copyright © 2017년 Wally. All rights reserved.
//

#ifndef CAUtils_h
#define CAUtils_h

#pragma mark - Singleton
#define SINGLETON(MYCLASS, METHODNAME)              \
\
+ (MYCLASS *)METHODNAME                             \
{                                                   \
static id uniqueInstance = nil;                     \
\
static dispatch_once_t onceToken;                   \
dispatch_once(&onceToken, ^{                        \
uniqueInstance  = [[MYCLASS alloc] init];           \
});                                                 \
\
return uniqueInstance;                              \
}                                                   \

#import <AudioToolbox/AudioToolbox.h>

#define USE_DEBUG_LOG 0

typedef struct WallyAUGraphPlayer
{
    AudioStreamBasicDescription inputFormat;
    AudioFileID					inputFile;
    ExtAudioFileRef sourceAudioFile;
    
    AUGraph graph;
    
    AUNode inPutNode;
    AUNode outPutNode;
    
    AudioUnit inPutUnit;
    AudioUnit outPutUnit;
    
    double startingFrameCount;
} CAAUGraphPlayer;

typedef struct {
    AudioStreamPacketDescription packetDescription;
    void *data;
} AudioPacketInfo;


#pragma mark - ERROR

struct CoreAudioCheckInfo {
    bool isErr;
    char *cmd;
};

/**
 에러체크
 
 @param error 에러사유
 @param operation Command
 @return Err != NULL
 */
struct CoreAudioCheckInfo CheckError(OSStatus error, const char *operation);

/**
 BufferList 할당
 
 @param frames 프레임 (default 1024)
 @param channels 채널 (default 2)
 @param interleaved 주기억장치에 접근 빨리할래?(default NO)
 */
AudioBufferList *AllocBufferList(UInt32 frames, UInt32 channels, bool interleaved);

/**
 BufferList에 데이터를 체웁니다.
 
 @param ioData OutPut Data
 @param currentPacketInfo inPut Info Data (struct AudioPacketInfo)
 @param outDataPacketDescription aspd
 */
void FillBufferList(AudioBufferList *ioData,AudioPacketInfo currentPacketInfo, AudioStreamPacketDescription** outDataPacketDescription);

#pragma mark - BUFFER_FREE

void CAudioBufferListFree(AudioBufferList *bufferList);
void CAudioPacketInfoFree(AudioPacketInfo *info);

#endif
