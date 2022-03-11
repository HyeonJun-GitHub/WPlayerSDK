//
//  CARemoteIO.m
//  Wally
//
//  Created by 김현준 on 13/02/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "CARemoteIO.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation CARemoteIO

#pragma mark - Node

void InputRemote(CAAUGraphPlayer *player,enum RemoteIO aRemote);
void OutputRemote(CAAUGraphPlayer *player,enum RemoteIO aRemote);
AUNode AddRemote(CAAUGraphPlayer *player,AudioComponentDescription cd);

AudioComponentDescription OutPutNode(CAAUGraphPlayer *player);
AudioComponentDescription FileNode(CAAUGraphPlayer *player);
AudioComponentDescription ConvertNode(CAAUGraphPlayer *player);

void InsertCARemoteIO(CAAUGraphPlayer *player,CARemote remote) {
    InputRemote(player,remote.input);
    OutputRemote(player,remote.output);
    
    CASuccess(CheckError(AUGraphNodeInfo(player->graph, player->inPutNode, NULL, &player->inPutUnit),
                         "AUGraphNodeInfo"));
    CASuccess(CheckError(AUGraphNodeInfo(player->graph, player->outPutNode, NULL, &player->outPutUnit),
                         "AUGraphNodeInfo"));
}

void InputRemote(CAAUGraphPlayer *player,enum RemoteIO aRemote) {
    
    AudioComponentDescription cd = {0};
    
    if (aRemote == RemoteAudioFilePlayer) {
        cd = FileNode(player);
    }
    
    if (aRemote == RemoteStream) {
        cd = ConvertNode(player);
    }
    
    player->inPutNode = AddRemote(player,cd);
}

void OutputRemote(CAAUGraphPlayer *player,enum RemoteIO aRemote) {
    
    AudioComponentDescription cd = {0};
    
    if (aRemote == RemoteSpeaker) {
        cd = OutPutNode(player);
    }
    
    player->outPutNode = AddRemote(player,cd);
}

AUNode AddRemote(CAAUGraphPlayer *player,AudioComponentDescription cd) {
    AUNode node;
    CASuccess(CheckError(AUGraphAddNode(player->graph, &cd, &node),
                         "AUGraphAddNode[kAudioUnitSubType_CARemoteIO]"));
    return node;
}

/**
 아웃풋(스피커)
 */
AudioComponentDescription OutPutNode(CAAUGraphPlayer *player) {
    
    AudioComponentDescription cd = {0};
    bzero(&cd, sizeof(AudioComponentDescription));
    cd.componentType = kAudioUnitType_Output;
#if !TARGET_OS_IPHONE
    cd.componentSubType = kAudioUnitSubType_DefaultOutput;
#else
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    return cd;
}

/**
 파일 입력
 */
AudioComponentDescription FileNode(CAAUGraphPlayer *player) {
    AudioComponentDescription cd = {
        .componentType = kAudioUnitType_Generator,
        .componentSubType = kAudioUnitSubType_AudioFilePlayer,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
    };
    return cd;
}

/**
 변환기
 */
AudioComponentDescription ConvertNode(CAAUGraphPlayer *player) {
    AudioComponentDescription cd = {
        .componentType          = kAudioUnitType_FormatConverter,
        .componentSubType       = kAudioUnitSubType_AUConverter,
        .componentManufacturer  = kAudioUnitManufacturer_Apple,
    };
    return cd;
}

@end
