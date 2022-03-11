//
//  CAParser.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 5. 31..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "CAParser.h"
#import "CADebug.h"

@implementation CAParser

void audioFileStreamPropertyListenerProc(void *inClientData, AudioFileStreamID	inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    /*
     kAudioFileStreamProperty_ReadyToProducePackets           =    'redy',
     kAudioFileStreamProperty_FileFormat                      =    'ffmt',
     kAudioFileStreamProperty_DataFormat                      =    'dfmt',
     kAudioFileStreamProperty_FormatList                      =    'flst',
     kAudioFileStreamProperty_MagicCookieData                 =    'mgic',
     kAudioFileStreamProperty_AudioDataByteCount              =    'bcnt',
     kAudioFileStreamProperty_AudioDataPacketCount            =    'pcnt',
     kAudioFileStreamProperty_MaximumPacketSize               =    'psze',
     kAudioFileStreamProperty_DataOffset                      =    'doff',
     kAudioFileStreamProperty_ChannelLayout                   =    'cmap',
     kAudioFileStreamProperty_PacketToFrame                   =    'pkfr',
     kAudioFileStreamProperty_FrameToPacket                   =    'frpk',
     kAudioFileStreamProperty_PacketToByte                    =    'pkby',
     kAudioFileStreamProperty_ByteToPacket                    =    'bypk',
     kAudioFileStreamProperty_PacketTableInfo                 =    'pnfo',
     kAudioFileStreamProperty_PacketSizeUpperBound            =    'pkub',
     kAudioFileStreamProperty_AverageBytesPerPacket           =    'abpp',
     kAudioFileStreamProperty_BitRate                         =    'brat',
     kAudioFileStreamProperty_InfoDictionary                  =    'info'
     */
    if (inPropertyID == 'dfmt') {
        AudioStreamBasicDescription description;
        UInt32 descriptionSize = sizeof(description);
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &descriptionSize, &description);
        [((__bridge CAParser *)inClientData).delegate audioStreamParser:(__bridge CAParser *)inClientData didObtainStreamDescription:&description];
    }
}


void audioFileStreamPacketsProc(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription	*inPacketDescriptions)
{
    [((__bridge CAParser *)inClientData).delegate audioStreamParser:((__bridge CAParser *)inClientData) packetData:inInputData dataLength:inNumberBytes packetDescriptions:inPacketDescriptions packetsCount:inNumberPackets];
}

- (id)init
{
    self = [super init];
    if (self) {
        AudioFileStreamOpen((__bridge void *)(self), audioFileStreamPropertyListenerProc, audioFileStreamPacketsProc, kAudioFileMP3Type, &_audioFileStreamID);
        
    }
    return self;
}

- (id)initWithType:(AudioFileTypeID)type
{
    self = [super init];
    if (self) {
        AudioFileStreamOpen((__bridge void *)(self), audioFileStreamPropertyListenerProc, audioFileStreamPacketsProc, type, &_audioFileStreamID);
        
    }
    return self;
}

- (void)parseData:(const void*)byte length:(UInt32)length
{
    AudioFileStreamParseBytes(_audioFileStreamID, length, byte, 0);
}

- (void)parseData:(NSData *)inData
{
    CASuccess(CheckError(AudioFileStreamParseBytes(_audioFileStreamID, (UInt32)[inData length], [inData bytes], 0), "AudioFileStreamParseBytes"));
}

- (void)parseClose
{
    CASuccess(CheckError(AudioFileStreamClose(_audioFileStreamID), "Closed File Stream"));
}

@synthesize delegate;
@end
