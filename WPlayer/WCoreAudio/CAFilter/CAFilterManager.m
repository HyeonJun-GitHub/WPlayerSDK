//
//  CAFilterManager.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 29..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CAFilterManager.h"
#import "CADebug.h"

@implementation CAFilterManagerUtil

int strchro(char c, char *str) {
    
    char *pch;
    int found = 0;
    pch=strchr(str,c);
    while (pch!=NULL)
    {
        found++;
        pch=strchr(pch+1,c);
    }
    return found;
}

size_t CstringCount(char cstring[]) {
    return sizeof(1)/sizeof(*cstring);
}

__attribute__((overloadable)) NSString *ConvertToString(int firstLength,int lastLength,char cstring[],size_t size)
{
    NSMutableString *str = [[NSMutableString alloc] initWithCapacity:size];
    for (int i=firstLength; i<lastLength; i++) {
        [str appendString:[NSString stringWithFormat:@"%c",cstring[i]]];
    }
    
    return str;
}

__attribute__((overloadable)) NSString *ConvertToString(UInt32 typeTitle)
{
    NSString *key = nil;
    
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(typeTitle);
    
    if (isprint(str[1]) && isprint(str[2]) &&
        isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        printf("TYPE ERROR!");
        //        exit(0);
    }
    
    size_t count = CstringCount(str);
    key = ConvertToString(1,(int)count+1,str,count);
    
    return [NSString stringWithFormat:@"%@",key];
}

NSString *FilterKeyByAudioType(AUEffectType type) {
    UInt32 typeKey = FilterCStringKey(type);
    
    NSString *key = nil;
    
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(typeKey);
    
    if (isprint(str[1]) && isprint(str[2]) &&
        isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        printf("TYPE ERROR!");
    }
    
    size_t count = CstringCount(str);
    key = ConvertToString(1,(int)count+1,str,count);
    
    return [NSString stringWithFormat:@"%@",key];
}

@end

@implementation CAFilterManager

#pragma mark - init

void initAudioUnitByUnit(AudioUnit unit,struct AudioEffecGroupType type) {
    
    CASuccess(CheckError(AudioUnitSetParameter(unit,
                                               type.subType,
                                               kAudioUnitScope_Global,
                                               0,
                                               FilterDefaultValues(type),
                                               0),
                         [NSString stringWithFormat:@"Coulnd't set %@",FilterKeyByAudioType(type.type)].UTF8String));
}


bool CheckAUFilter(CAFilterManager *filterManager, struct AudioEffecGroupType type) {
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    if ([filterManager.filters objectForKey:key]) {
        
        return YES;
    }
    
    return NO;
}


bool initAudioUnitByFilterManager(CAFilterManager *filterManager, struct AudioEffecGroupType type) {
    
    CAFilter *filter = nil;
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    
    if ([filterManager.filters objectForKey:key]) {
        
        filter = [filterManager.filters objectForKey:key];
        
        initAudioUnitByUnit(filter.audioUnit,type);
        
        return YES;
        
    }
    
    return NO;
}

bool CheckAudioUnitFilter(CAFilterManager *filterManager, struct AudioEffecGroupType type) {
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    if ([filterManager.filters objectForKey:key]) {
        
        return YES;
    }
    
    return NO;
}


void AUGraphAllConnectNodeInput(CAFilterManager *filterManager, CAAUGraphPlayer *player) {
    
    NSArray *allKey = [filterManager.filters allKeys];
    
    for (int i = 0; i < allKey.count +1; i++) {
        
        if (i == 0) {
            
            CAFilter *cur_filter = filterManager.filters[allKey[i]];
            CASuccess(CheckError(AUGraphConnectNodeInput(player->graph, player->inPutNode, 0, cur_filter.node, 0),
                                 "first ->Content Node"));
        }else{
            
            CAFilter *pre_filter = filterManager.filters[allKey[i-1]];
            
            if (i == allKey.count) {
                CASuccess(CheckError(AUGraphConnectNodeInput(player->graph, pre_filter.node, 0, player->outPutNode, 0),
                                     "Content Node->Last Node"));
            }else{
                
                CAFilter *cur_filter = filterManager.filters[allKey[i]];
                CASuccess(CheckError(AUGraphConnectNodeInput(player->graph, pre_filter.node, 0, cur_filter.node, 0),
                                     "first Node-> Content Node"));
            }
        }
    }
}


#pragma mark - add/remove

- (void)addFilter:(CAFilter *)filter FilterType:(AUEffectType)type {
    
    if (!_filters)_filters = [[NSDictionary alloc] init];
    
    NSString *typeKey = FilterKeyByAudioType(type);
    
    NSMutableDictionary *dicM = [[self.filters copy] mutableCopy];
    [dicM setObject:filter forKey:typeKey];
    
    self.filters = [[NSDictionary alloc] initWithDictionary:dicM];
}


- (BOOL)removeFilter:(AUEffectType)type {
    
    if (!_filters) return NO;
    
    NSString *typeKey = FilterKeyByAudioType(type);
    
    NSMutableDictionary *dicM = [[self.filters copy] mutableCopy];
    
    if ([dicM objectForKey:typeKey]) {
        
        [dicM removeObjectForKey:typeKey];
        
        return YES;
    }
    
    return NO;
}


- (void)addAUEffects:(AUEffectOption)options player:(CAAUGraphPlayer *)player {
    
    if (options & AUEffectOptionReverb) {
        [self addAUEffectType:AUReverbType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionPitch) {
        [self addAUEffectType:AUPitchType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionBandPass) {
        [self addAUEffectType:AUBandPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionHighPass) {
        [self addAUEffectType:AUHighPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionLowPass) {
        [self addAUEffectType:AULowPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionHighShelf) {
        [self addAUEffectType:AUHighShelfType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionLowShelf) {
        [self addAUEffectType:AULowShelfType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionParametricEQ) {
        [self addAUEffectType:AUParametricEQType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionPeakLimiter) {
        [self addAUEffectType:AUPeakLimiterType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionNBandEQ) {
        CAFilter *filter = [self addAUEffectType:AUNBandEQType ToGraph:player->graph];
        CreateBandEQ(filter,player);
    }
    
    if (options & AUEffectOptionDynamicsProcessor) {
        [self addAUEffectType:AUDynamicsProcessorType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionMixer) {
        UInt32 busCount = 1;
        CAFilter *filter = [self addAUEffectType:AUMixerType ToGraph:player->graph];
        AudioUnitSetProperty(filter.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
    }
}



- (CAFilter *)addAUEffectType:(AUEffectType)type ToGraph:(AUGraph)graph {
    
    NSString *key = FilterKeyByAudioType(type);
    
    CAFilter *filter = self.filters[key];
    
    if (!filter)filter = [[CAFilter alloc] init];
    
    
    AudioComponentDescription cd = createComponentDescription(type);
    
    AudioUnit unit = filter.audioUnit;
    
    AUNode node = filter.node;
    
    
    CASuccess(CheckError(AUGraphAddNode(graph, &cd, &node),
                         [NSString stringWithFormat:@"AUGraphAddNode AudioUnitSubType %@",key].UTF8String));
    
    CASuccess(CheckError(AUGraphNodeInfo(graph, node, NULL, &unit),
                         [NSString stringWithFormat:@"AUGraphNodeInfo AudioUnitSubType %@",key].UTF8String));
    
    
    filter.audioUnit = unit;
    filter.node = node;
    
    [self addFilter:filter FilterType:type];
    
    return filter;
}

- (void)removeAUEffects:(AUEffectOption)options player:(CAAUGraphPlayer *)player {
    
    if (options & AUEffectOptionReverb) {
        [self removeAUEffectType:AUReverbType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionPitch) {
        [self removeAUEffectType:AUPitchType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionBandPass) {
        [self removeAUEffectType:AUBandPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionHighPass) {
        [self removeAUEffectType:AUHighPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionLowPass) {
        [self removeAUEffectType:AULowPassType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionHighShelf) {
        [self removeAUEffectType:AUHighShelfType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionLowShelf) {
        [self removeAUEffectType:AULowShelfType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionParametricEQ) {
        [self removeAUEffectType:AUParametricEQType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionPeakLimiter) {
        [self removeAUEffectType:AUPeakLimiterType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionNBandEQ) {
        [self removeAUEffectType:AUNBandEQType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionDynamicsProcessor) {
        [self removeAUEffectType:AUDynamicsProcessorType ToGraph:player->graph];
    }
    
    if (options & AUEffectOptionMixer) {
        [self removeAUEffectType:AUMixerType ToGraph:player->graph];
    }
}

- (void)removeAUEffectType:(AUEffectType)type ToGraph:(AUGraph)graph {
    
    NSString *key = FilterKeyByAudioType(type);
    
    CAFilter *filter = self.filters[key];
    
    AUNode node = filter.node;
    
    
    CASuccess(CheckError(AUGraphRemoveNode(graph,node),
                         [NSString stringWithFormat:@"AUGraphRemoveNode AudioUnitSubType %@",key].UTF8String));
    
    BOOL isRemoved = [self removeFilter:type];
    
    if (!isRemoved)printf("Remove AudioUnit %s",key.UTF8String);
}


-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type {
    
    [self setUpAudioUnitEQValue:value eQBandNum:0 AudioEffecGroupType:type];
}

-(void)setUpAudioUnitDirectValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type {
    
    if (!_filters) return;
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    AudioUnitParameterValue calculatedValue = AUParamCal(type,value);
    
    if ([self.filters objectForKey:key]) {
        
        CAFilter *filter = [self.filters objectForKey:key];
        
        CheckError(AudioUnitSetParameter(filter.audioUnit,
                                         type.subType,
                                         kAudioUnitScope_Input,
                                         0,
                                         calculatedValue,
                                         0),
                   [NSString stringWithFormat:@"AudioUnitSetParameter Set %@",key].UTF8String);
    }
}

-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type {
    
    if (!_filters) return;
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    AudioUnitParameterValue calculatedValue = AUParamCal(type,value);
    
    if ([self.filters objectForKey:key]) {
        
        CAFilter *filter = [self.filters objectForKey:key];
        
        CheckError(AudioUnitSetParameter(filter.audioUnit,
                                         type.subType + num,
                                         kAudioUnitScope_Global,
                                         0,
                                         calculatedValue,
                                         0),
                   [NSString stringWithFormat:@"AudioUnitSetParameter Set %@",key].UTF8String);
    }
}

-(AudioUnitParameterValue)getAudioUnitValueWithAudioEffecGroupType:(struct AudioEffecGroupType)type {
    
    return [self getAudioUnitEQValueWithEQBandNum:0 AudioEffecGroupType:type];
}

-(AudioUnitParameterValue)getAudioUnitEQValueWithEQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type {
    
    if (!_filters) {
        return 0;
    }
    
    NSString *key = FilterKeyByAudioType(type.type);
    
    AudioUnitParameterValue paramterValue;
    UInt32 size = sizeof(paramterValue);
    if (![self.filters objectForKey:key]) {
        return 0;
    }
    
    CAFilter *filter = [self.filters objectForKey:key];
    
    CheckError(AudioUnitGetProperty(filter.audioUnit,
                                    type.subType + num,
                                    kAudioUnitScope_Global,
                                    0,
                                    &paramterValue,
                                    &size),
               [NSString stringWithFormat:@"AudioUnitSetParameter Get %@",key].UTF8String);
    
    return paramterValue;
}

#pragma mark - Band EQ

void CreateBandEQ(CAFilter *filter, CAAUGraphPlayer *player) {
    
    NSArray *eqFrequencies = @[@63.f,   @125.f,  @250.f,  @500.f,   @1000.f,  @2000.f,
                               @4000.f,  @8000.f, @12500.f, @16000.f];
    
    
    
    NSArray *eqBypass = @[@0, @0, @0, @0, @0, @0, @0, @0, @0, @0];
    
    UInt32 noBands = (UInt32)[eqFrequencies count];
    
    CASuccess(CheckError(AudioUnitSetProperty(filter.audioUnit,
                                              kAUNBandEQProperty_NumberOfBands,
                                              kAudioUnitScope_Global,
                                              0,
                                              &noBands,
                                              sizeof(noBands)),
                         "AudioUnitSetProperty[kAUNBandEQProperty_NumberOfBands]"));
    
    for (NSUInteger i=0; i<noBands; i++) {
        CASuccess(CheckError(AudioUnitSetParameter(filter.audioUnit,
                                                   (AudioUnitParameterID)(kAUNBandEQParam_Frequency+i),
                                                   kAudioUnitScope_Global,
                                                   0,
                                                   (AudioUnitParameterValue)[[eqFrequencies objectAtIndex:i] floatValue],
                                                   0),
                             "AudioUnitSetParameter[EQ Set frequencies]"));
    }
    
    for (NSUInteger i=0; i<noBands; i++) {
        CASuccess(CheckError(AudioUnitSetParameter(filter.audioUnit,
                                                   (AudioUnitParameterID)(kAUNBandEQParam_BypassBand+i),
                                                   kAudioUnitScope_Global,
                                                   0,
                                                   (AudioUnitParameterValue)[[eqBypass objectAtIndex:i] intValue],
                                                   0),
                             "AudioUnitSetParameter[EQ Set ByPass]"));
    }
}

#pragma mark - File Info

//double PrepareFileAU(CAAUGraphPlayer *player, Float64 time, Float64 startFrame)
//{
//    CASuccess(CheckError(AudioUnitSetProperty(player->inPutUnit,
//                                    kAudioUnitProperty_ScheduledFileIDs,
//                                    kAudioUnitScope_Global,
//                                    0,
//                                    &player->inputFile,
//                                    sizeof(player->inputFile)),
//               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs]"));
//
//    UInt64 nPackets;
//    UInt32 propsize = sizeof(nPackets);
//    CASuccess(CheckError(AudioFileGetProperty(player->inputFile, kAudioFilePropertyAudioDataPacketCount,
//                                    &propsize, &nPackets),
//               "AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount]"));
//
//    //파일재생기 AU에 전체 파일을 재생하라고 명령
//    ScheduledAudioFileRegion rgn;
//    memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
//    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
//    rgn.mTimeStamp.mSampleTime = 0;
//    rgn.mCompletionProc = NULL;
//    rgn.mCompletionProcUserData = NULL;
//    rgn.mAudioFile = player->inputFile;
//    rgn.mLoopCount = 1;
//    rgn.mStartFrame = startFrame == 0?0:(UInt32)nPackets * player->inputFormat.mFramesPerPacket * startFrame;
//    rgn.mFramesToPlay = (UInt32)nPackets * player->inputFormat.mFramesPerPacket;
//
//
//    CASuccess(CheckError(AudioUnitSetProperty(player->inPutUnit,
//                                    kAudioUnitProperty_ScheduledFileRegion,
//                                    kAudioUnitScope_Global,
//                                    0,&rgn,
//                                    sizeof(rgn)),
//               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion]"));
//
//
//    UInt32 defaultVal = 0;
//    CASuccess(CheckError(AudioUnitSetProperty(player->inPutUnit,
//                                    kAudioUnitProperty_ScheduledFilePrime,
//                                    kAudioUnitScope_Global,
//                                    0,
//                                    &defaultVal,
//                                    sizeof(defaultVal)),
//               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime]"));
//
//
//    AudioTimeStamp startTime;
//    memset (&startTime, 0, sizeof(startTime));
//    startTime.mFlags = kAudioTimeStampSampleTimeValid;
//    startTime.mSampleTime = -1;
//    CASuccess(CheckError(AudioUnitSetProperty(player->inPutUnit,
//                                    kAudioUnitProperty_ScheduleStartTimeStamp,
//                                    kAudioUnitScope_Global,
//                                    0,
//                                    &startTime,
//                                    sizeof(startTime)),
//               "AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]"));
//
//    return (nPackets * player->inputFormat.mFramesPerPacket);// / player->inputFormat.mSampleRate;
//}

@end
