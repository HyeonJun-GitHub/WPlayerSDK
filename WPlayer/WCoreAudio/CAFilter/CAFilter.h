//
//  CAFilter.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 28..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CAUnit.h"

/**
 CoreAudio 필터 계산 카테고리
 */
@interface CAFilterCal : NSObject

/**
 울림
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue reverbValue(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 음역대
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue pitchValue(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 사운드 센터 위치
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue bandPassCalW(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 HighPass
 
 @param type 타입
 @param value 값
 @return 결과값
 */
AudioUnitParameterValue highPassCalValue(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 LowPass
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue LowPassCalR(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 HighShelf
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue HighShelfPassCalG(struct AudioEffecGroupType type,AudioUnitParameterValue value);
///ComponentDescription

/**
 LowShelf
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue LowShelfPassCalG(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 parametricEQ
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue parametricEQ_G(struct AudioEffecGroupType type,AudioUnitParameterValue value);


/**
 PeakLimiter
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue peakLimiter_G(struct AudioEffecGroupType type,AudioUnitParameterValue value);


/**
 NBandEQ
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue nBandEQ_G(struct AudioEffecGroupType type,AudioUnitParameterValue value);

/**
 값 조절
 
 @param type 타입
 @param value 값
 @return 결과 값
 */
AudioUnitParameterValue AUParamCal(struct AudioEffecGroupType type,AudioUnitParameterValue value);

@end

/**
 CoreAudio 필터
 */
@interface CAFilter : NSObject

/**
 Grouping AudioUnit
 */
@property (assign) AudioUnit audioUnit;

/**
 Grouping Node
 */
@property (assign) AUNode node;

/**
 타입에 따라 ComponentDescription 생성
 
 @param type 생성 할 타입
 @return AudioComponentDescription
 */
AudioComponentDescription createComponentDescription(AUEffectType type);

/**
 CString 필터키 문자열을 가져옵니다.
 
 @param type 가져올 키 타입
 @return CString 필터키 문자열
 */
UInt32 FilterCStringKey(AUEffectType type);


/**
 필터 DefaultValues
 
 @param type 타겟 타입,서브타입
 @return Value
 */
AudioUnitParameterValue FilterDefaultValues(struct AudioEffecGroupType type);


@end
