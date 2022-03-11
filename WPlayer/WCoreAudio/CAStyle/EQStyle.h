//
//  EQStyle.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 4. 19..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 사용자가 저장한 EQ스타일을 여기서 구현해야함
 */
@interface EQStyle : NSObject

@property (nonatomic,strong) NSArray *eqParam;
@end

@interface EQNormal : EQStyle
@end

@interface EQCleanSound : EQStyle
@end

@interface EQAcoustic : EQStyle
@end

@interface EQBallad : EQStyle
@end

@interface EQClassic : EQStyle
@end

@interface EQDance : EQStyle
@end

@interface EQJazz : EQStyle
@end

@interface EQPop : EQStyle
@end

@interface EQHipHop : EQStyle
@end

@interface EQRnB : EQStyle
@end

@interface EQRock : EQStyle
@end

@interface EQBassBoost : EQStyle
@end

@interface EQVocalBoost : EQStyle
@end
