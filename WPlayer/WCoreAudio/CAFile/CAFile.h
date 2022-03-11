//
//  CAFile.h
//  Wally
//
//  Created by 김현준 on 22/01/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct CAFileInfo {
    __unsafe_unretained NSString *title;
    __unsafe_unretained NSString *artist;
    __unsafe_unretained NSString *albumName;
    __unsafe_unretained NSString *lyrics;
    __unsafe_unretained NSString *duration;
};

@interface CAFile : NSObject
struct CAFileInfo GetAudioFileInfo(NSURL *url);
@end

NS_ASSUME_NONNULL_END
