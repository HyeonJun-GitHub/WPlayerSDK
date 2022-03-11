//
//  CAUnit.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 4. 13..
//  Copyright © 2017년 Wally. All rights reserved.
//
#ifndef CAUnit_h
#define CAUnit_h

#import <AudioToolbox/AudioToolbox.h>

/**
 @brief Effect NS_ENUM
 
 - reverbUnitType: 울림
 - pitchUnitType: 음역대
 - bandPassUnitType: 일정범위
 - highPassUnitType: 높은주파수 내보냄
 - lowPassUnitType: 낮은주파수 내보냄
 - highShelfUnitType: 최고음역 제어
 - lowShelfUnitType: 최저음역 제어
 - parametricEQUnitType: 증폭,중심 주파수,대역폭의 설정을 허용
 - peakLimiterUnitType: 어느 수준의 높이를 치닫는 특정 주파수의 증폭을 줄임
 - AUNBandEQType : EQ
 - dynamicsProcessorUnitType : 고급 볼륨 조절
 - AUNoneType : 이펙트 없음
 */
typedef NS_ENUM(NSInteger,AUEffectType) {
    AUReverbType              = 0,
    AUPitchType               ,
    AUBandPassType            ,
    AUHighPassType            ,
    AULowPassType             ,
    AUHighShelfType           ,
    AULowShelfType            ,
    AUParametricEQType        ,
    AUPeakLimiterType         ,
    AUNBandEQType             ,
    AUDynamicsProcessorType   ,
    AUMixerType               = 100,
    AUNoneType                = 9999,
};


/**
 @brief AUEffectType 유닛 옵션
 */
typedef NS_OPTIONS(NSInteger,AUEffectOption) {
    AUEffectOptionReverb              = 1 << AUReverbType,
    AUEffectOptionPitch               = 1 << AUPitchType,
    AUEffectOptionBandPass            = 1 << AUBandPassType,
    AUEffectOptionHighPass            = 1 << AUHighPassType,
    AUEffectOptionLowPass             = 1 << AULowPassType,
    AUEffectOptionHighShelf           = 1 << AUHighShelfType,
    AUEffectOptionLowShelf            = 1 << AULowShelfType,
    AUEffectOptionParametricEQ        = 1 << AUParametricEQType,
    AUEffectOptionPeakLimiter         = 1 << AUPeakLimiterType,
    AUEffectOptionNBandEQ             = 1 << AUNBandEQType,
    AUEffectOptionDynamicsProcessor   = 1 << AUDynamicsProcessorType,
    AUEffectOptionMixer               = 1 << AUMixerType,
    AUEffectOptionNone                = 1 << AUNoneType,
};

/**
 @brief 음향 컨트롤
 - enum AUEffectType : 이펙트 타입
 - AudioUnitParameterID : 서브타입
 */
struct AudioEffecGroupType {
    AUEffectType type;
    AudioUnitParameterID subType;
};


#endif
