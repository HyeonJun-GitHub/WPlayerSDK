//
//  CADebug.m
//  Wally
//
//  Created by 김현준 on 21/11/2018.
//  Copyright © 2018 wally. All rights reserved.
//
#import "CADebug.h"
@implementation CADebug

BOOL CASuccess(struct CoreAudioCheckInfo info) {
    if (!info.isErr) {
        return YES;
    }
    
    if (info.cmd == NULL) {
        return NO;
    }
    
    NSString * LOG = [NSString stringWithUTF8String:info.cmd];
    if (LOG.length) {
        free(info.cmd);
        info.cmd = NULL;
        NSLog(@"LOG_COREAUDIO : %@",LOG);
    }
    return !info.isErr;
}

@end
