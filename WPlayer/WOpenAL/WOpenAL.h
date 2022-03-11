//
//  ALProcessor.h
//  KTmPlayer
//
//  Created by 김현준 on 2017. 7. 21..
//  Copyright © 2017년 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUtil.h"

@interface WOpenAL : NSObject
@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic,assign) ALfloat x;
@property (nonatomic,assign) ALfloat y;
@property (nonatomic,assign) ALfloat z;


/**
 OpenAL Start
 @param openUrl 오디오파일 Url
 */
- (void)ALProcessing:(NSURL *)openUrl;


/**
 3D 사운드 좌표
 @param x 좌우
 @param y 위아래
 @param z 높이
 */
-(void)updateSourceLocation:(ALfloat)x :(ALfloat)y :(ALfloat)z;


/**
 오디오 컨트롤러
 */
- (void)stop;
- (void)playAL;
- (void)pauseAL;
@end

@interface WOpenAL(Util)
void CheckALError (const char *operation);
@end
