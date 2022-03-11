//
//  CAConfig.m
//  Wally
//
//  Created by 김현준 on 09/09/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "CAConfig.h"
#import "GContentsManager.h"
#import "CAFilterManager.h"
#import "WPlayer.h"

@implementation CAConfig

SINGLETON(CAConfig, instance);

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _isEq = [aDecoder decodeBoolForKey:@"isEq"];
        _eqDicM = [aDecoder decodeObjectForKey:@"eqDicM"];
        _soundInfo = [aDecoder decodeObjectForKey:@"soundInfo"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:self.isEq forKey:@"isEq"];
    [aCoder encodeObject:self.eqDicM forKey:@"eqDicM"];
    [aCoder encodeObject:self.soundInfo forKey:@"soundInfo"];
}

- (void)save {
    NSString *path = GetFilePath(@"EQ_CONFIG",@"plist");
    SaveArchiving(self,[CAConfig class],path);
}

- (void)load {
    
    NSString *eqConfigPath = GetFilePath(@"EQ_CONFIG",@"plist");
    CAConfig *config = LoadArchiving([self class],eqConfigPath);
    
    self.isEq = config.isEq;
    self.eqDicM = config.eqDicM;
    self.soundInfo = config.soundInfo;
    
    if (!self.soundInfo[@"MutePreValue"]) {
        self.soundInfo = @{@"isMute":@"N",@"MutePreValue":@(0.5)}.mutableCopy;
    }
}

#pragma mark - EQ

+ (void)loadCAValue {
    for (NSString *key in [CAConfig instance].eqDicM.allKeys) {
        
        if ([key rangeOfString:@"_"].location == NSNotFound) {
            continue;
        }
        
        NSArray *ary = [key componentsSeparatedByString:@"_"];
        float value = [[CAConfig instance].eqDicM[key] floatValue];
        
        if (![CAConfig instance].isEq) {
            value = 0;
        }
        
        NSInteger tag = [ary[1] integerValue];
        
        if (tag >= EQ_TAG) {
            tag -= EQ_TAG;
            
            if ([ary[0] isEqual:FilterKeyByAudioType(AUNBandEQType)]) {
                SetUpAudioUnitEQValue(value, (UInt32)tag);
            }
        }else{
            SetUpAudioUnitEQGlobalValue(value);
        }
    }
}

- (NSMutableDictionary *)eqDicM {
    if (!_eqDicM) {
        _eqDicM = [[NSMutableDictionary alloc] init];
    }
    return _eqDicM;
}

- (NSMutableDictionary *)soundInfo {
    if (!_soundInfo) {
        _soundInfo = [[NSMutableDictionary alloc] init];
    }
    return _soundInfo;
}

@end
