//
//  CASound.h
//  Wally
//
//  Created by 김현준 on 07/01/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CASoundControl DEBUG

NS_ASSUME_NONNULL_BEGIN

@interface CASound : NSObject
#if CASoundControl


/**
 현재 오디오를 찾을수 없을경우
 현재 설정되어있는 오디오로 다시 재설정합니다.
 */
void SetUpAudioDevice(void);

/**
 오디오를 등록합니다.
 @param targetDevice AirPlay, VoilaDevice
 @return 오디오 등록 성공 / 실패
 */
BOOL AudioOutput(NSString *targetDevice);
NSString *CAudioDevice(void);
#endif

@end

NS_ASSUME_NONNULL_END
