//
//  CADownload.m
//  Wally
//
//  Created by 김현준 on 2018. 4. 26..
//  Copyright © 2018년 wally. All rights reserved.
//

#import "CADownload.h"
#import "CAUtils.h"

#import "WPlayer.h"

static NSString *STREAMING_BUFFER_NOTI = @"NOTI_DOWNLOAD_STREAM_BUFFER";

@interface CADownload()
@property (nonatomic,assign) NSInteger retryCtn;
@property (nonatomic,assign) NSInteger dataReceivedCnt; //10단위로 끊음, Debug Log용..
@property (nonatomic,strong) NSString *streamingUrl;
@property (nonatomic,strong) NSDictionary *headerField;
@property (nonatomic,strong) NSURLSessionDataTask *task;
@property (nonatomic,strong) NSURLSession *operationSession;
@end

@implementation CADownload

SINGLETON(CADownload, instance);

#pragma mark - Networking

- (BOOL)listUpUrls:(NSArray *)urls {
    
    if (!urls) {
        return YES;
    }
    
    if (urls.count == 0) {
        return YES;
    }
    
    return NO;
}

- (NSURLSessionDataTask *)streamingPlayWithUrls:(NSArray <NSString*>*)urls target:(id)target headerFieldInfo:(NSDictionary *)headerInfo {
    
    _delegate = target;
    
    if ([self listUpUrls:urls]) {
        if ([self.delegate respondsToSelector:@selector(didCompleteWithError:)]) {
            NSError *errMsg = [NSError errorWithDomain:@"Streaming Download" code:1001 userInfo:@{                                                                                      NSLocalizedDescriptionKey:@"Urls Empty!"}];
            [self.delegate didCompleteWithError:errMsg];
        }
    }
    
    NSString *LOG = [NSString stringWithFormat:@"\
                     [HTTP STREAM REQUEST] %@ RETRY:%@",urls.firstObject,@(_retryCtn)];
    NSLog(@"LOG_API : %@",LOG);
    
    _headerField = headerInfo;
    _streamingUrl = [urls firstObject];
    
    return [self downloadStreamingWithUrlStr:_streamingUrl headerFieldInfo:headerInfo];
}

- (NSURLSessionDataTask *)downloadStreamingWithUrlStr:(NSString *)urlStr headerFieldInfo:(NSDictionary *)headerInfo {
    
    if (_task) {
        [_task cancel];
        _task = nil;
        
        [_operationSession invalidateAndCancel];
        _operationSession = nil;
    }
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *myConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    _operationSession = [NSURLSession sessionWithConfiguration:myConfiguration delegate:(id)self delegateQueue:operationQueue];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    if (headerInfo.count) {
        for (NSString *key in headerInfo.allKeys) {
            [request setValue:headerInfo[key] forHTTPHeaderField:key];
        }
    }
    _task = [_operationSession dataTaskWithRequest:request];
    [_task resume];
    return _task;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    //통신상태
    int status = (int)[(NSHTTPURLResponse*)response statusCode];
    self.state = DOWNLOAD_START;
    
    //데이터
    _currentDataLength = 0;
    _dataReceivedCnt = 0;
    _contentLength = response.expectedContentLength;
    NSDictionary* headers = [(NSHTTPURLResponse*)response allHeaderFields];
    NSString *actualContentLength = headers[@"Content-Length"];
    if(actualContentLength.length){
        _contentLength = actualContentLength.intValue;
    }
    
    NSString *LOG = [NSString stringWithFormat:@"[STREAM RECEIVE_STATUS] (%@)",@(status)];
    NSLog(@"LOG_STREAM : %@",LOG);
    
    //Check..
    if (status != HTTP_SUCCESS) {
        
        if ([self.delegate respondsToSelector:@selector(didCompleteWithError:)]) {
            [self.delegate didCompleteWithError:nil];
        }
        [self stopTask];
        
        //종료..
        if (_retryCtn > 2) {
            _retryCtn = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"POPUP_CMD_NOTIFY" object:nil userInfo:@{@"CMD":@"곡 수신에 실패하였습니다.\n잠시 후 다시 시도해 주시기 바랍니다."}];
            });
            return;
        }
        
#if DEBUG
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TOAST_CMD_NOTIFY" object:nil userInfo:@{@"CMD":[NSString stringWithFormat:@"CDN:재요청(%@회)",@(self.retryCtn)]}];
        });
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self streamingPlayWithUrls:@[self.streamingUrl] target:self headerFieldInfo:self.headerField];
        });
        _retryCtn++;
        return;
    }
    
    if (_contentLength < 44100) {
        if ([self.delegate respondsToSelector:@selector(didCompleteWithError:)]) {
            [self.delegate didCompleteWithError:nil];
        }
        [self stopTask];
        return;
    }
    
    //Success..
    if ([self.delegate respondsToSelector:@selector(didReceiveResponse:)]) {
        [self.delegate didReceiveResponse:_contentLength];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (self.state == DOWNLOAD_ERROR) {
        [self stopTask];
        return;
    }
    
    self.state = DOWNLOAD_ING;
    
    _currentDataLength += data.length;
    float size = (float)_currentDataLength / (float)_contentLength * 100;
    
    int logSize = size;
    if (logSize % 10 == 0 && _dataReceivedCnt != logSize) {
        self.dataReceivedCnt = logSize;
        NSString *LOG = [NSString stringWithFormat:@"\
                         [STREAM RECEIVE_DATA] %.2fMB (%@%%)",(float)_currentDataLength/1024.0f/1024.0f,@(logSize)];
        NSLog(@"LOG_STREAM : %@",LOG);
    }
    
    if (!_delegate) {
        [self stopTask];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didReceiveData:currentSize:)]) {
        [self.delegate didReceiveData:data currentSize:size];
        
        BOOL isStream = [self.delegate isKindOfClass:[PlayerClass() class]];
        NSMutableDictionary *infoM = [NSMutableDictionary new];
        if (_streamingUrl.length) {
            infoM[@"URL"] = _streamingUrl;
            infoM[@"IS_STREAM"] = isStream?@"Y":@"N";
        }
        infoM[@"SIZE"] = @(size);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STREAMING_BUFFER_NOTI object:nil userInfo:infoM];
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(didCompleteWithError:)]) {
        [self.delegate didCompleteWithError:error];
    }
    [self stopTask];
    [session finishTasksAndInvalidate];
    session = nil;
}

- (void)stopTask {
    
    _contentLength = 0;
    _currentDataLength = 0;
    self.state = DOWNLOAD_COMPLETE;
    
    if (_task) {
        [_task cancel];
        _task = nil;
        
        [_operationSession invalidateAndCancel];
        _operationSession = nil;
    }
}

- (void)didReceiveData:(NSData *)data {
    if (self.state == DOWNLOAD_ERROR) {
        [self stopTask];
        return;
    }
    
    self.state = DOWNLOAD_ING;
    
    _currentDataLength += data.length;
    float size = (float)_currentDataLength / (float)_contentLength * 100;
    
    if (!_delegate) {
        [self stopTask];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didReceiveData:currentSize:)]) {
        [self.delegate didReceiveData:data currentSize:size];
        
        BOOL isStream = [self.delegate isKindOfClass:[PlayerClass() class]];
        NSMutableDictionary *infoM = [NSMutableDictionary new];
        if (_streamingUrl.length) {
            infoM[@"URL"] = _streamingUrl;
            infoM[@"IS_STREAM"] = isStream?@"Y":@"N";
        }
        infoM[@"SIZE"] = @(size);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STREAMING_BUFFER_NOTI object:nil userInfo:infoM];
        });
    }
}

@end

@implementation CADownload(Util)

AudioFileTypeID MediaMimeType(NSString* MIMEType) {
    if ( MIMEType == nil || MIMEType.length == 0 )
        return NO;
    
    MIMEType = [MIMEType uppercaseString];
    if ([MIMEType rangeOfString:@"AUDIO"].location != NSNotFound)   return kAudioFileAAC_ADTSType;
    if ([MIMEType rangeOfString:@"MP3"].location != NSNotFound)     return kAudioFileMP3Type;
    if ([MIMEType rangeOfString:@"MP4"].location != NSNotFound)     return kAudioFileMPEG4Type;
    if ([MIMEType rangeOfString:@"VIDEO"].location != NSNotFound)   return kAudioFileM4AType;
    return NO;
}

@end

