//
//  CAFilterManager.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 3. 29..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAFilter.h"
#import "CAUtils.h"

#define MIX_EFFECT 0
/**
 개발 디버그 LOG
 
 @param info CoreAudio OSStatus
 @return 성공여부
 */
BOOL CASuccess(struct CoreAudioCheckInfo info);

/**
 CAFilter 관리 Class Helper
 */
@interface CAFilterManagerUtil : NSObject

/**
 문자열에서 Char검색
 
 @param c 검색할 Char
 @param str 문자열
 @return 몇번째 자리인지
 */
int strchro(char c, char *str);


/**
 char 길이를 구합니다.
 
 @param cstring 문자열
 @return 문자열 길이
 */
size_t CstringCount(char cstring[]);


/** 
 @brief char -> NSString
 @attention 32Bit를 지원하기 때문에 size_t사용
 @note 문자열 firstLength ~ lastLength 까지 추출
 
 @param firstLength 추출할 첫번째 문자
 @param lastLength 추출할 마지막 문자
 @param cstring 변환할 문자열
 @param size 문자열 크기
 @return 변환된 문자열
 */
__attribute__((overloadable)) NSString *ConvertToString(int firstLength,int lastLength,char cstring[],size_t size);


/**
 @brief UInt32 -> NSString
 
 @param typeTitle 변환할 문자열
 @return 변환된 문자열
 */
__attribute__((overloadable)) NSString *ConvertToString(UInt32 typeTitle);


/**
 오디오타입을 키값으로 변환, 그 키값은 필터들의 정보를 담고 있는 맵의 키값이 됨
 
 @param type 키값으로 변환한 타입
 @return 타입을 키값으로 변환
 */
NSString *FilterKeyByAudioType(AUEffectType type);

@end


/**
 CAFilter 관리 Class
 */
@interface CAFilterManager : NSObject

@property (nonatomic,assign) Float64 sampleFrameSavedPosition;

/**
 현재 가동중인 음장 Filter Class
 */
@property (nonatomic,strong) NSDictionary *filters;

#pragma mark - init

/**
 AudioUnit Value 초기화
 
 @param unit 타겟 유닛
 @param type 초기화할 유닛타입,서브타입
 */
void initAudioUnitByUnit(AudioUnit unit,struct AudioEffecGroupType type);


/**
 필터에 타입이 있는지 체크
 
 @param filterManager 필터 매니저
 @param type 타입
 @return 필터 매니저 타입 유무
 */
bool CheckAUFilter(CAFilterManager *filterManager, struct AudioEffecGroupType type);

/**
 AudioUnit Value 초기화
 
 @param filterManager 타겟 필터 매니저
 @param type AudioEffecGroupType 초기화할 유닛타입,초기화할 유닛 서브타입
 @return 초기화 성공여부
 */
bool initAudioUnitByFilterManager(CAFilterManager *filterManager, struct AudioEffecGroupType type);



/**
 사용자가 필터를 등록했는지 확인
 
 @param filterManager 필터 매니저
 @param type 타입
 @return 타입을 요청했었는지
 */
bool CheckAudioUnitFilter(CAFilterManager *filterManager, struct AudioEffecGroupType type);

/**
 노드 등록
 
 @param filterManager 필터 매니저 인스턴스
 @param player 타겟 플레이어
 */
void AUGraphAllConnectNodeInput(CAFilterManager *filterManager, CAAUGraphPlayer *player);

/**
 AudioUnit Setup Value
 
 @param value 변경할 값
 @param type 타겟 타입,서브 타입
 */
-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type;


/**
 AudioUnit EQ Setup Value
 
 @param value Gain
 @param num 밴드 Number
 @param type 타입
 */
-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type;


/**
 해당 Unit에 다이렉트 대응
 
 @param value Gain
 @param type 타입
 */
-(void)setUpAudioUnitDirectValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type;

/**
 AudioUnit EQ Get Value
 
 @param type 타입
 @return value Gain
 */
-(AudioUnitParameterValue)getAudioUnitValueWithAudioEffecGroupType:(struct AudioEffecGroupType)type;

/**
 AudioUnit EQ Get Value
 
 @param num 밴드 Numbver
 @param type 타입
 @return value Gain
 */
-(AudioUnitParameterValue)getAudioUnitEQValueWithEQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type;

/**
 현재 가동중인 필터로 부터 제거
 
 @param type 제거 할 타입
 */
- (BOOL)removeFilter:(AUEffectType)type;


/**
 Graph/Node에서 선택한 UnitType들을 추가한다.
 
 @param options 선택한 옵션 (복수)
 @param player 플레이어
 */
- (void)addAUEffects:(AUEffectOption)options player:(CAAUGraphPlayer *)player;


/**
 Graph/Node에서 선택한 UnitType을 추가한다.
 
 @param type 추가 할 타입
 @param graph 타겟 Graph
 */
- (CAFilter *)addAUEffectType:(AUEffectType)type ToGraph:(AUGraph)graph;


/**
 현재 가동중인 필터에 추가
 
 @param filter 추가 할 필터 Class
 @param type 추가 할 타입
 */
- (void)addFilter:(CAFilter *)filter FilterType:(AUEffectType)type;


/**
 Graph/Node에서 선택한 UnitType들을 제거한다.
 
 @param options 제거 할 타입들
 @param player 타겟 Graph
 */
- (void)removeAUEffects:(AUEffectOption)options player:(CAAUGraphPlayer *)player;


/**
 Graph/Node에서 선택한 UnitType을 제거한다.
 
 @param type 제거 할 타입
 @param graph 타겟 Graph
 */
- (void)removeAUEffectType:(AUEffectType)type ToGraph:(AUGraph)graph;

#pragma mark - Band EQ


/**
 밴드EQ를 등록합니다.
 
 @param filter EQ Filter
 @param player AUGraph
 */
void CreateBandEQ(CAFilter *filter, CAAUGraphPlayer *player);

#pragma mark - File Info


/**
 파일 정보(길이)를 가져옵니다.
 
 @param player      AUGraph
 @param time        재시작 시간
 @param startFrame  재시작 시간
 @return 파일 길이
 */
double PrepareFileAU(CAAUGraphPlayer *player, Float64 time, Float64 startFrame);

@end
