//
//  CARemoteIO.h
//  Wally
//
//  Created by 김현준 on 13/02/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CADebug.h"


enum RemoteIO {
    RemoteAudioFilePlayer,
    RemoteStream,
    RemoteSpeaker,
};

/**
 CARemote 입/출력 리모트
 
 - enum RemoteIO: 입력
 - enum RemoteIO: 출력
 */
typedef struct CARemote {
    enum RemoteIO input;
    enum RemoteIO output;
} CARemote;


NS_ASSUME_NONNULL_BEGIN

@interface CARemoteIO : NSObject

void InsertCARemoteIO(CAAUGraphPlayer *player,CARemote remote);

@end

NS_ASSUME_NONNULL_END
