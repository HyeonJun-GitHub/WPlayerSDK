//
//  CADownload.h
//  Wally
//
//  Created by 김현준 on 2018. 4. 26..
//  Copyright © 2018년 wally. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>

enum CADownloadState {
    DOWNLOAD_START,
    DOWNLOAD_ING,
    DOWNLOAD_COMPLETE,
    DOWNLOAD_ERROR,
};

static const NSInteger HTTP_SUCCESS = 200;

@protocol CADownloadDelegate<NSObject>
- (void)didReceiveResponse:(long long)contentLength;
- (void)didReceiveData:(NSData *)data currentSize:(float)size;
- (void)didCompleteWithError:(NSError *)error;
@end

@interface CADownload : NSObject
@property (nonatomic,assign) id<CADownloadDelegate>delegate;
@property (nonatomic,assign) enum CADownloadState state;
@property (nonatomic,assign) long long currentDataLength;
@property (nonatomic,assign) long long contentLength;

+ (CADownload *)instance;
- (NSURLSessionDataTask *)streamingPlayWithUrls:(NSArray <NSString*>*)urls target:(id)target headerFieldInfo:(NSDictionary *)headerInfo;
- (void)stopTask;
@end

@interface CADownload(Util)

AudioFileTypeID MediaMimeType(NSString* MIMEType);

@end

