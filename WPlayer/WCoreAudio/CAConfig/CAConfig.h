//
//  CAConfig.h
//  Wally
//
//  Created by 김현준 on 09/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
static NSInteger EQ_TAG = 1000;

NS_ASSUME_NONNULL_BEGIN

@interface CAConfig : NSObject
/*
 @ func     : instanceCAConfig
 @ desc     : 싱글톤
 */
+(CAConfig *)instance;

#pragma mark - EQ
@property (nonatomic,assign) BOOL isEq;
@property (nonatomic,strong) NSMutableDictionary *eqDicM;   //Volume : 100 / EQ : 1000~1010
@property (nonatomic,strong) NSMutableDictionary *soundInfo;
- (void)save;
- (void)load;
+ (void)loadCAValue;
@end

NS_ASSUME_NONNULL_END
