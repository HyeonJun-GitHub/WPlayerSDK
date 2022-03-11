//
//  CAConverter.h
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CABuffer.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, CAAudioFileType) {
    CAAudioFileTypeM4A= 0,
    CAAudioFileTypeFloat32,
};

@interface CAConverter : NSObject
{
    AudioStreamPacketDescription *packetDescriptions;
    AudioStreamBasicDescription audioStreamDescription;
    AudioConverterRef converter;
    UInt32 renderBufferSize;
    UInt32 packetsPerBuffer;
}
@property (nonatomic,assign) AudioStreamBasicDescription destFormat;
@property (nonatomic,assign) AudioBufferList *renderBufferList;
__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(UInt32 ch,double sampleRate,CAAudioFileType fileType);
__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(double sampleRate,CAAudioFileType fileType);
__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(CAAudioFileType fileType);

/**
 instancetype
 
 @param sourceFormat ASBD
 @return Class Object
 */
- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription *)sourceFormat;
- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription *)sourceFormat destFormat:(AudioStreamBasicDescription)dest;

/**
 버스에 받아온 데이타를 태움
 
 @param inNumberOfFrames 프레임
 @param inIoData 데이타
 @param inBusNumber 버스
 @param inBuffer 버퍼
 @return 성공유무
 */
- (OSStatus)requestNumberOfFrames:(UInt32)inNumberOfFrames ioData:(AudioBufferList  *)inIoData busNumber:(UInt32)inBusNumber buffer:(CABuffer *)inBuffer;

- (void)stop;

+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate;
@end
