//
//  CAConverter.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CAConverter.h"
#import "CAUtils.h"
#import "CADebug.h"

static UInt32 FloatConverterDefaultOutputBufferSize = 128 * 32;
UInt32 const FloatConverterDefaultPacketSize = 2048;

OSStatus AudioConverterFiller (AudioConverterRef inAudioConverter, UInt32* ioDataPacketCount, AudioBufferList* ioData, AudioStreamPacketDescription** outDataPacketDescription, void* inUserData)
{
    NSArray *args = (__bridge NSArray *)inUserData;
    CABuffer *buffer = args[1];
    
    UInt32 byteSize = (unsigned int)buffer.currentPacketInfo.packetDescription.mDataByteSize;
    if (byteSize == 0) {
        return 1;
    }
    
    //버퍼를 체웁니다.
    FillBufferList(ioData, buffer.currentPacketInfo, outDataPacketDescription);
    
    //패킷인덱스를 다음으로 진행합니다.
    [buffer movePacketReadIndex];
    return noErr;
}

AudioStreamBasicDescription CACreateASBD(UInt32 channelCount, Float64 sampleRate, CAAudioFileType fileType) {
    
    AudioStreamBasicDescription asbd;
    asbd.mChannelsPerFrame  = channelCount;
    asbd.mSampleRate       = sampleRate;
    
    if (fileType == CAAudioFileTypeM4A) {
        AudioStreamBasicDescription asbd;
        memset(&asbd, 0, sizeof(asbd));
        asbd.mFormatID          = kAudioFormatMPEG4AAC;
        UInt32 propSize = sizeof(asbd);
        AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,0,NULL,&propSize,&asbd);
            
    }
    
    if (fileType == CAAudioFileTypeFloat32) {
        UInt32 floatByteSize   = sizeof(float);
        asbd.mBitsPerChannel   = 8 * floatByteSize;
        asbd.mBytesPerFrame    = floatByteSize;
        asbd.mBytesPerPacket   = floatByteSize;
        asbd.mChannelsPerFrame = channelCount;
        asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
        asbd.mFormatID         = kAudioFormatLinearPCM;
        asbd.mFramesPerPacket  = 1;
        
    }
    
    return asbd;
}

__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(UInt32 ch,double sampleRate,CAAudioFileType fileType) {
    return CACreateASBD(ch,sampleRate,fileType);
}

__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(double sampleRate,CAAudioFileType fileType) {
    return CACreateASBD(1,sampleRate,fileType);
}

__attribute__((overloadable)) AudioStreamBasicDescription CACreatePCM(CAAudioFileType fileType) {
    return CACreateASBD(1,44100,fileType);
}

@implementation CAConverter

- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription *)sourceFormat
{
    return [self initWithSourceFormat:sourceFormat destFormat:CACreatePCM(CAAudioFileTypeFloat32)];
}

- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription *)sourceFormat destFormat:(AudioStreamBasicDescription)dest
{
    self = [super init];
    if (self) {
        audioStreamDescription = *sourceFormat;
        _destFormat = dest;
        
        CASuccess(CheckError(AudioConverterNew(&audioStreamDescription, &_destFormat, &converter), "AudioConverterNew"));
        UInt32 second = 1;
        UInt32 packetSize = sourceFormat->mSampleRate * second * 8;
        renderBufferSize = packetSize;
        [self setup];
    }
    return self;
}

- (void)setup {
    UInt32 packetsPerBuffer = 0;
    UInt32 outputBufferSize = FloatConverterDefaultOutputBufferSize;
    UInt32 sizePerPacket = audioStreamDescription.mBytesPerPacket;
    BOOL isVBR = sizePerPacket == 0;
    
    // VBR
    if (isVBR)
    {
        UInt32 maxOutputPacketSize;
        UInt32 propSize = sizeof(maxOutputPacketSize);
        OSStatus result = AudioConverterGetProperty(converter,
                                                    kAudioConverterPropertyMaximumOutputPacketSize,
                                                    &propSize,
                                                    &maxOutputPacketSize);
        if (result != noErr)
        {
            maxOutputPacketSize = FloatConverterDefaultPacketSize;
        }
        
        if (maxOutputPacketSize > outputBufferSize)
        {
            outputBufferSize = maxOutputPacketSize;
        }
        packetsPerBuffer = outputBufferSize / maxOutputPacketSize;
        self->packetDescriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * packetsPerBuffer);
    }
    else
    {
        packetsPerBuffer = outputBufferSize / sizePerPacket;
    }
    
    self.renderBufferList = AllocBufferList(packetsPerBuffer, _destFormat.mChannelsPerFrame, !(_destFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved));
}

- (OSStatus)requestNumberOfFrames:(UInt32)inNumberOfFrames ioData:(AudioBufferList  *)inIoData busNumber:(UInt32)inBusNumber buffer:(CABuffer *)inBuffer
{
    UInt32 packetSize = inNumberOfFrames;
    NSArray *args = @[self, inBuffer];
    OSStatus status = noErr;
    
    [CAConverter freeBufferList:self.renderBufferList];
    self.renderBufferList = AllocBufferList(inNumberOfFrames * _destFormat.mChannelsPerFrame, _destFormat.mChannelsPerFrame, !(_destFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved));
    
    @synchronized(inBuffer) {
        UInt32 frames = inIoData->mBuffers[0].mDataByteSize / _destFormat.mBytesPerFrame;
        status = AudioConverterFillComplexBuffer(converter, AudioConverterFiller, (__bridge void *)(args), &frames, self.renderBufferList, self->packetDescriptions);
    }
    
    if (status > 0) {
        AudioConverterReset(converter);
    }
    
    if (noErr == status && packetSize) {
        for (int i = 0; i < _destFormat.mChannelsPerFrame; i++) {
            inIoData->mBuffers[i].mNumberChannels = _destFormat.mChannelsPerFrame;
            inIoData->mBuffers[i].mDataByteSize = self.renderBufferList->mBuffers[i].mDataByteSize;
            inIoData->mBuffers[i].mData = self.renderBufferList->mBuffers[i].mData;
        }
        status = noErr;
    }
    return status;
}

+ (void)freeBufferList:(AudioBufferList *)bufferList
{
    if (bufferList)
    {
        if (bufferList->mNumberBuffers)
        {
            for( int i = 0; i < bufferList->mNumberBuffers; i++)
            {
                if (bufferList->mBuffers[i].mData)
                {
                    free(bufferList->mBuffers[i].mData);
                }
            }
        }
        free(bufferList);
    }
    bufferList = NULL;
}

- (void)stop {
    
    @try {
        if (!converter) {
            return;
        }
        
        AudioConverterDispose(converter);
        [CAConverter freeBufferList:self.renderBufferList];
        free(self->packetDescriptions);
        AudioConverterReset(converter);
    } @catch (NSException *exception) {
        
    }
}


+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate
{
    AudioStreamBasicDescription asbd;
    UInt32 floatByteSize   = sizeof(float);
    asbd.mBitsPerChannel   = 8 * floatByteSize;
    asbd.mBytesPerFrame    = floatByteSize;
    asbd.mBytesPerPacket   = floatByteSize;
    asbd.mChannelsPerFrame = channels;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mSampleRate       = sampleRate;
    return asbd;
}

@end
