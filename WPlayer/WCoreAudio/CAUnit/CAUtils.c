//
//  CAUtils.c
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 15..
//  Copyright © 2017년 Wally. All rights reserved.
//

#include <stdio.h>
#include "CAUtils.h"
#if USE_DEBUG_LOG
struct CoreAudioCheckInfo CheckError(OSStatus error, const char *operation) {
    
    char *title = "[CORE_AUDIO] ";
    char *cmd = error == noErr?" SUCCESS":" FAIL DESC : ";
    char *errLog;
    
    if (error == noErr) {
        
        errLog = malloc(sizeof(char) * (strlen(title) + strlen(cmd) + strlen(operation)));
        strcat(errLog, title);
        strcat(errLog, operation);
        strcat(errLog, cmd);
        
        struct CoreAudioCheckInfo info = {0};
        info.isErr = false;
        info.cmd   = errLog;
        
        return info;
    }
    
    char errDesc[20];
    *(UInt32 *)(errDesc + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errDesc[1]) && isprint(errDesc[2]) &&
        isprint(errDesc[3]) && isprint(errDesc[4])) {
        errDesc[0] = errDesc[5] = '\'';
        errDesc[6] = '\0';
    }
    
    errLog = malloc(sizeof(char) * (strlen(title) + strlen(cmd) + strlen(operation) + strlen(errDesc)));
    
    strcat(errLog, title);
    strcat(errLog, operation);
    strcat(errLog, cmd);
    strcat(errLog, errDesc);
    
    struct CoreAudioCheckInfo info = {0};
    info.isErr = true;
    info.cmd   = errLog;
    
    return info;
}
#else
struct CoreAudioCheckInfo CheckError(OSStatus error, const char *operation) {
#if !USE_DEBUG_LOG
    struct CoreAudioCheckInfo info = {0};
    info.isErr = error != noErr;
    return info;
#else
    if (error == noErr) {
        struct CoreAudioCheckInfo info = {0};
        info.isErr = false;
        return info;
    }
    
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) &&
        isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "\n[CORE AUDIO Error] %s (%s)\n", operation, str);
    
    struct CoreAudioCheckInfo info = {0};
    info.isErr = true;
    
    char *title = "\n[CORE AUDIO Error] ";
    char *space = " ";
    size_t title_len = strlen(title);
    size_t space_len = strlen(space);
    size_t operation_len = strlen(operation);
    size_t str_len = strlen(str);
    
    char *resultStr = malloc(sizeof(char) * (title_len + space_len + operation_len + str_len));
    
    strcat(resultStr, title);
    strcat(resultStr, space);
    strcat(resultStr, operation);
    strcat(resultStr, str);
    
    
    info.cmd = resultStr;
    free(resultStr);
    return info;
#endif
}

#endif

#pragma mark - DATA

void CAudioBufferListFree(AudioBufferList *bufferList) {
    if (!bufferList) {
        return;
    }
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        if ( bufferList->mBuffers[i].mData ) {
            free(bufferList->mBuffers[i].mData);
            bufferList->mBuffers[i].mData = NULL;
        }
    }
    free(bufferList);
    bufferList = NULL;
}

void freeData(void **f);

void CAudioPacketInfoFree(AudioPacketInfo *info) {
    
    if (!info) {
        return;
    }
    
    if (info->data == NULL) {
        return;
    }
    
    free(info->data);
    info->data = NULL;
}

AudioBufferList *AllocBufferList(UInt32 frames, UInt32 channels, bool interleaved) {
    
    AudioBufferList *audioBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (channels-1));
    UInt32 outputBufferSize = 32 * frames; // 32 KB
    audioBufferList->mNumberBuffers = interleaved ? 1 : channels;
    for(int i = 0; i < audioBufferList->mNumberBuffers; i++)
    {
        audioBufferList->mBuffers[i].mNumberChannels = channels;
        audioBufferList->mBuffers[i].mDataByteSize = channels * outputBufferSize;
        audioBufferList->mBuffers[i].mData = (float *)malloc(channels * sizeof(float) *outputBufferSize);
        memset(audioBufferList->mBuffers[i].mData, 0, frames);
    }
    return audioBufferList;
}

void FillBufferList(AudioBufferList *ioData,AudioPacketInfo currentPacketInfo, AudioStreamPacketDescription** outDataPacketDescription) {
    //초기화..
    ioData -> mBuffers[0].mData = NULL;
    ioData -> mBuffers[0].mDataByteSize = 0;
    static AudioStreamPacketDescription aspdesc;
    void *data = currentPacketInfo.data;
    UInt32 length = (UInt32)currentPacketInfo.packetDescription.mDataByteSize;
    ioData->mBuffers[0].mData = data;
    ioData->mBuffers[0].mDataByteSize = length;
    *outDataPacketDescription = &aspdesc;
    aspdesc.mDataByteSize = length;
    aspdesc.mStartOffset = 0;
    aspdesc.mVariableFramesInPacket = 1;
}
