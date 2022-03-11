//
//  CAFilter.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 28..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CAFilter.h"
#import "CADebug.h"

static UInt32 NONE_TYPE = '0000';
static float HIPASS_COTOFF_MAX = 384.f;

@implementation CAFilterCal

AudioUnitParameterValue reverbValue(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue pitchValue(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue bandPassCalW(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    
    AudioUnitParameterValue result = value;
    
    //    result = 1200 * log2(value / 440) + 6900;
    
    return result;
}

AudioUnitParameterValue highPassCalValue(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = 0;
    
    switch (type.subType) {
            
        case kHipassParam_CutoffFrequency:
            result = HIPASS_COTOFF_MAX - value;
            break;
        case kHipassParam_Resonance:
            result = value;
            break;
            
        default:
            break;
    }
    
    return result;
}

AudioUnitParameterValue LowPassCalR(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue HighShelfPassCalG(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue LowShelfPassCalG(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue parametricEQ_G(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue peakLimiter_G(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    AudioUnitParameterValue result = value;
    
    return result;
}

AudioUnitParameterValue nBandEQ_G(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    
    AudioUnitParameterValue result = value;
    
    return result;
}


AudioUnitParameterValue AUParamCal(struct AudioEffecGroupType type,AudioUnitParameterValue value) {
    
    AudioUnitParameterValue result = value;
    
    switch (type.type) {
#if TARGET_OS_IPHONE
        case AUReverbType:            result = reverbValue(type,value);        break;
#endif
        case AUPitchType:             result = pitchValue(type,value);         break;
        case AUBandPassType:          result = bandPassCalW(type,value);       break;
        case AUHighPassType:          result = highPassCalValue(type,value);   break;
        case AULowPassType:           result = LowPassCalR(type,value);        break;
        case AUHighShelfType:         result = HighShelfPassCalG(type,value);  break;
        case AULowShelfType:          result = LowShelfPassCalG(type,value);   break;
        case AUParametricEQType:      result = parametricEQ_G(type,value);     break;
        case AUPeakLimiterType:       result = peakLimiter_G(type,value);      break;
        case AUNBandEQType:           result = nBandEQ_G(type, value);         break;
        case AUDynamicsProcessorType: result = value;                          break;
        case AUMixerType:             result = value;                          break;
        default:                                                               break;
    }
    return result;
}


@end

@implementation CAFilter

@synthesize audioUnit = _audioUnit;
@synthesize node = _node;

/**
 Audio 컴포넌트 생성
 
 @param type 생성할 컴포넌트 타입
 @return Audio 컴포넌트
 */
AudioComponentDescription createComponentDescription(AUEffectType type) {
    
    AudioComponentDescription cd = {0};
    
    switch (type) {
#if TARGET_OS_IPHONE
        case AUReverbType:            cd = [CAFilter reverbCD];               break;
#endif
        case AUPitchType:             cd = [CAFilter pitchCD];                break;
        case AUBandPassType:          cd = [CAFilter bandPassCD];             break;
        case AUHighPassType:          cd = [CAFilter highPassCD];             break;
        case AULowPassType:           cd = [CAFilter lowPassCD];              break;
        case AUHighShelfType:         cd = [CAFilter highShelfPassCD];        break;
        case AULowShelfType:          cd = [CAFilter lowShelfPassCD];         break;
        case AUParametricEQType:      cd = [CAFilter parametricEQCD];         break;
        case AUPeakLimiterType:       cd = [CAFilter peakLimiterCD];          break;
        case AUNBandEQType:           cd = [CAFilter nBandEqCD];              break;
        case AUDynamicsProcessorType: cd = [CAFilter dynamicsProcessorCD];    break;
        case AUMixerType:             cd = [CAFilter mixerCD];
        default:break;
    }
    return cd;
}

AudioComponentDescription CommonCD(OSType type, OSType subType) {
    AudioComponentDescription cd = {
        .componentType = type,
        .componentSubType = subType,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
    };
    return cd;
}

AudioComponentDescription EffectCD(OSType subType) {
    return CommonCD(kAudioUnitType_Effect,subType);
}


#if TARGET_OS_IPHONE
/**
 울림
 */
+(AudioComponentDescription)reverbCD {
    return EffectCD(kAudioUnitSubType_Reverb2);
}
#endif

/**
 음역대
 */
+(AudioComponentDescription)pitchCD {
    return CommonCD(kAudioUnitType_FormatConverter, kAudioUnitSubType_NewTimePitch);
}


/**
 사운드 센터 위치
 */
+(AudioComponentDescription)bandPassCD {
    return EffectCD(kAudioUnitSubType_BandPassFilter);
}


/**
 HighPass
 */
+(AudioComponentDescription)highPassCD {
    return EffectCD(kAudioUnitSubType_HighPassFilter);
}


/**
 LowPass
 */
+(AudioComponentDescription)lowPassCD {
    return EffectCD(kAudioUnitSubType_LowPassFilter);
}


/**
 HighShelf
 */
+(AudioComponentDescription)highShelfPassCD {
    return EffectCD(kAudioUnitSubType_HighShelfFilter);
}


/**
 LowShelf
 */
+(AudioComponentDescription)lowShelfPassCD {
    return EffectCD(kAudioUnitSubType_LowShelfFilter);
}


/**
 parametricEQ
 */
+(AudioComponentDescription)parametricEQCD {
    return EffectCD(kAudioUnitSubType_ParametricEQ);
}


/**
 PeakLimiter
 */
+(AudioComponentDescription)peakLimiterCD {
    return EffectCD(kAudioUnitSubType_PeakLimiter);
}

/**
 NBandEQ
 */
+(AudioComponentDescription)nBandEqCD {
    return EffectCD(kAudioUnitSubType_NBandEQ);
}

/**
 DynamicsProcessor
 */
+(AudioComponentDescription)dynamicsProcessorCD {
    return EffectCD(kAudioUnitSubType_DynamicsProcessor);
}

/**
 믹서
 */
+(AudioComponentDescription)mixerCD {
    return CommonCD(kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer);
}


UInt32 FilterCStringKey(AUEffectType type) {
    
    UInt32 typeKey = 0;
    
    switch (type) {
#if TARGET_OS_IPHONE
        case AUReverbType:            typeKey = kAudioUnitSubType_Reverb2;            break;
#endif
        case AUPitchType:             typeKey = kAudioUnitSubType_NewTimePitch;       break;
        case AUBandPassType:          typeKey = kAudioUnitSubType_BandPassFilter;     break;
        case AUHighPassType:          typeKey = kAudioUnitSubType_HighPassFilter;     break;
        case AULowPassType:           typeKey = kAudioUnitSubType_LowPassFilter;      break;
        case AUHighShelfType:         typeKey = kAudioUnitSubType_HighShelfFilter;    break;
        case AULowShelfType:          typeKey = kAudioUnitSubType_LowShelfFilter;     break;
        case AUParametricEQType:      typeKey = kAudioUnitSubType_ParametricEQ;       break;
        case AUPeakLimiterType:       typeKey = kAudioUnitSubType_PeakLimiter;        break;
        case AUNBandEQType:           typeKey = kAudioUnitSubType_NBandEQ;            break;
        case AUDynamicsProcessorType: typeKey = kAudioUnitSubType_DynamicsProcessor;  break;
        case AUMixerType:             typeKey = kAudioUnitSubType_MultiChannelMixer;  break;
        default:                      typeKey = NONE_TYPE;                            break;
            
    }
    return typeKey;
}

AudioUnitParameterValue FilterDefaultValues(struct AudioEffecGroupType type) {
    AudioUnitParameterValue value = 0;
    switch (type.type) {
#if TARGET_OS_IPHONE
        case AUReverbType:
            if      (type.subType == kReverb2Param_DryWetMix)            value = 0;
            break;
#endif
        case AUPitchType:
            if      (type.subType == kNewTimePitchParam_Pitch)           value = 1.0f;
            break;
        case AUBandPassType:
            if      (type.subType == kBandpassParam_CenterFrequency)     value = 640;
            else if (type.subType == kBandpassParam_Bandwidth)           value = 9250;
            break;
        case AUHighPassType:
            if      (type.subType == kHipassParam_CutoffFrequency)       value = 201.5f;
            else if (type.subType == kHipassParam_Resonance)             value = 0;
            break;
        case AULowPassType:
            if      (type.subType == kLowPassParam_CutoffFrequency)      value = 7500;
            else if (type.subType == kLowPassParam_Resonance)            value = 0;
            break;
        case AUHighShelfType:
            if      (type.subType == kHighShelfParam_CutOffFrequency)    value = 10000;
            else if (type.subType == kHighShelfParam_Gain)               value = 0;
            break;
        case AULowShelfType:
            if      (type.subType == kAULowShelfParam_CutoffFrequency)   value = 96;
            else if (type.subType == kAULowShelfParam_Gain)              value = 0;
            break;
        case AUParametricEQType:
            if      (type.subType == kParametricEQParam_CenterFreq)      value = 8000;
            else if (type.subType == kParametricEQParam_Q)               value = 3.0f;
            else if (type.subType == kParametricEQParam_Gain)            value = 0;
            break;
        case AUPeakLimiterType:
            if      (type.subType == kLimiterParam_PreGain)              value = 0;
            break;
        case AUNBandEQType:
            if      (type.subType == kAUNBandEQParam_Gain)               value = 0;
            break;
        case AUDynamicsProcessorType:
            if      (type.subType == kDynamicsProcessorParam_Threshold)  value = -12.7;
            else if (type.subType == kDynamicsProcessorParam_MasterGain) value = 0;
            break;
            
        case AUMixerType:
            //            if      (type.subType == kAudioUnitType_Mixer)  value = -12.7;
            if (type.subType == kMultiChannelMixerParam_Volume) value = 1;
            break;
            
        default:
            value = 0;
            break;
    }
    return value;
}

@end
