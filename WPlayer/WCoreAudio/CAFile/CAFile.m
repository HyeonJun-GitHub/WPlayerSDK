//
//  CAFile.m
//  Wally
//
//  Created by 김현준 on 22/01/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "CAFile.h"
#import "CADebug.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation CAFile

struct CAFileInfo GetAudioFileInfo(NSURL *url) {
    
    NSString*fileExtension = [url pathExtension];
    if ([fileExtension isEqual:@"mp3"]||[fileExtension isEqual:@"m4a"]||[fileExtension isEqualToString:@"flac"]||[fileExtension isEqualToString:@"aac"])
    {
        AudioFileID fileID  = nil;
        
        CASuccess(CheckError(AudioFileOpenURL((__bridge CFURLRef)url,kAudioFileReadPermission,0,&fileID),"AudioFileOpenURL Failed"));
        
        UInt32 id3DataSize  =0;
        CASuccess(CheckError(AudioFileGetPropertyInfo(fileID,kAudioFilePropertyID3Tag,&id3DataSize,NULL ),"AudioFileGetPropertyInfo Failed for ID3 tag"));
        
        NSDictionary *piDic      = nil;
        UInt32        piDataSize = sizeof(piDic);
        CASuccess(CheckError(AudioFileGetProperty(fileID,kAudioFilePropertyInfoDictionary,&piDataSize,&piDic), "AudioFileGetProperty[Dictionary] Failed for property info"));
        
        CFDataRef AlbumPic = nil;
        UInt32 picDataSize = sizeof(picDataSize);
        CASuccess(CheckError(AudioFileGetProperty(fileID,  kAudioFilePropertyAlbumArtwork,&picDataSize,&AlbumPic),"Get Picture Failed"));
        
        NSString *title = [piDic objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Title]];
        NSString *artist = [piDic objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Artist]];
        NSString *albumName = [piDic objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Album]];
        NSString *lyrics = [piDic objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Lyricist]];
        NSString *duration = [piDic objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_ApproximateDurationInSeconds]];
        
        title = title.length?title:@"<unknown>";
        title = [NSString stringWithFormat:@"%@",[CAFile encoding:title]];
        
        artist = artist.length?artist:@"<unknown>";
        artist = [NSString stringWithFormat:@"%@",[CAFile encoding:artist]];
        
        albumName = albumName.length?albumName:@"<unknown>";
        albumName = [NSString stringWithFormat:@"%@",[CAFile encoding:albumName]];
        
        lyrics = lyrics.length?lyrics:@"";
        lyrics = [NSString stringWithFormat:@"%@",[CAFile encoding:lyrics]];
        
        duration = [NSString stringWithFormat:@"%@",duration.length?duration:@""];
        
        struct CAFileInfo info = {
            .title = title,
            .artist = artist,
            .albumName = albumName,
            .lyrics = lyrics,
            .duration = duration,
        };
        
        return info;
    }
    
    struct CAFileInfo info = {
        .title = @"<unknown>",
        .artist = @"<unknown>",
        .albumName = @"<unknown>",
        .lyrics = @"",
        .duration = @"",
    };
    
    return info;
}

+ (NSString *)encoding:(NSString *)str {
    
    NSUInteger encoding = 0;
    NSString *tempStr = nil;
    const char *cString = [str cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    if (cString) {
        encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR);
        tempStr = [NSString stringWithCString:cString encoding:encoding];
    }
    
    if (tempStr.length) {
        return tempStr;
    }
    
    return str;
}

@end
