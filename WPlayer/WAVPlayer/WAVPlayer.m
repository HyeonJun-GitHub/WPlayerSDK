//
//  GAVPlayer.m
//  AudioTest
//
//  Created by 김현준 on 2017. 7. 11..
//
//

#import "WAVPlayer.h"
#import "CADownload.h"
#if HAS_GDEBUG
#import "GDebug.h"
#endif

#import <CoreServices/CoreServices.h>

#pragma mark - Singleton
#define SINGLETON(MYCLASS, METHODNAME)              \
\
+ (MYCLASS *)METHODNAME                             \
{                                                   \
static id uniqueInstance = nil;                     \
\
static dispatch_once_t onceToken;                   \
dispatch_once(&onceToken, ^{                        \
uniqueInstance  = [[MYCLASS alloc] init];           \
});                                                 \
\
return uniqueInstance;                              \
}                                                   \

static void *GAVPlayerItemStatusContext = &GAVPlayerItemStatusContext;
static void *GAVPlayerRateContext = &GAVPlayerRateContext;
static void *GAVPlayerCurrentItemContext = &GAVPlayerCurrentItemContext;

@interface WAVPlayer()
@property (nonatomic,strong) NSMutableData *dataM;
@property (nonatomic,strong) NSMutableDictionary *muteInfo;
@property (nonatomic,strong) NSURLSessionDataTask *task;
@end

@implementation WAVPlayer {
    NSInteger sec;
}

SINGLETON(WAVPlayer, instance);

- (id)init {
    self = [super init];
    if (self) {
        self.state = STOP;
    }
    return self;
}

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys completionHandler:(void(^)(BOOL isError))completionHandler
{
    for (NSString *key in keys) {
        NSError *error = nil;
        if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed){
            
            if (!completionHandler) {
                return;
            }
            
            completionHandler(YES);
            
            if (error.code == -999) {
                return;
            }
            
            dispatch_async(self.player_q, ^{
                [self stop];
                [[NSNotificationCenter defaultCenter] postNotificationName:PlayerStateNotify object:nil userInfo:@{@"STATE":@(ERROR)}];
            });
            return;
        }
    }
    
    if (!asset.isPlayable || asset.hasProtectedContent)return;
    
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
        
    }else{
        
    }
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self addObserver];
    
    if (self.muteInfo) {
        NSString *checkMute = self.muteInfo[@"isMute"];
        if ([checkMute isEqual:@"Y"]) {
            [WAVPlayer soundVolume:0];
        }else{
            NSNumber *num = self.muteInfo[@"MutePreValue"];
            Float64 value = num.floatValue;
            [WAVPlayer soundVolume:value];
        }
    }
    
    __weak typeof(self)THIS = self;
    [self setTimeObserverToken:[self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if ([THIS isCheckPlayed]) {
            [THIS playedItem];
        }
    }]];
    
    self.state = PLAYING;
    [self.player play];
    
    if (completionHandler) {
        completionHandler(NO);
    }
}

- (BOOL)playWithUrl:(NSString *)url {
    return [self playWithUrl:url muteInfo:nil completionHandler:nil];
}

- (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)info {
    return [self playWithUrl:url muteInfo:info completionHandler:nil];
}

- (BOOL)playWithUrl:(NSString *)url muteInfo:(NSMutableDictionary *)info completionHandler:(void(^)(BOOL isError))completionHandler {
    return [self playWithUrl:url muteInfo:info header:@{} body:@{} completionHandler:completionHandler];
}
    
- (BOOL)playWithUrl:(NSString *)urlStr muteInfo:(NSMutableDictionary *)info header:(NSDictionary *)header body:(NSDictionary *)body completionHandler:(void(^)(BOOL isError))completionHandler {
    self.muteInfo = info;
    
    NSString *LOG = [NSString stringWithFormat:@"[GAVPLAYER] Start Url : %@",urlStr];
    NSLog(@"%@",LOG);
    NSRange r = [urlStr rangeOfString:@"http://"];
    NSRange r_ssl = [urlStr rangeOfString:@"https://"];
    _isStreaming = r.location != NSNotFound || r_ssl.location != NSNotFound;
    _streamingUrl = urlStr;
    
    NSURL *url = _isStreaming?[NSURL URLWithString:urlStr]:[NSURL fileURLWithPath:urlStr];
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:@{@"AVURLAssetHTTPHeaderFieldsKey": header}];
    NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks"];
    __weak typeof(self)THIS = self;
    _player = [AVPlayer new];
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
        [THIS setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest completionHandler:completionHandler];
    }];
    
    self.state = START;
    
    return YES;
}

#pragma mark - CA Notify

- (void)caProcessNotificationStatus:(NSNotification *)center {
    
    if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
        [self.delegate observeValueForKeyPath:center.name ofObject:center.object];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == GAVPlayerItemStatusContext)
    {
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            return;
        }
        
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerItemStatusUnknown:
                NSLog(@"[GAVPlayerItemStatus] Unknown");
                sec = 0;
                break;
            case AVPlayerItemStatusReadyToPlay:
                if (self.player) {
                    [self.player play];
                    if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
                        [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(START)];
                    }
                }
                
                NSLog(@"[GAVPlayerItemStatus] ReadyToPlay");
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"[GAVPlayerItemStatus] Failed");
                if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
                    [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(STOP)];
                }
                break;
        }
    }
    else if (context == GAVPlayerRateContext)
    {
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            return;
        }
        
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        BOOL isPause = rate != 1.f;
        enum PlayerState state = isPause?PAUSE:PLAYING;
        if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
            [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(state)];
        }
        
        if (!isPause) {
            return;
        }
        
        if([self isCheckPlayed]) {
            [self playedItem];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)isCheckPlayed {
    
    Float64 cur_f = CMTimeGetSeconds(self.player.currentTime);
    int cur = round(cur_f);
    int duration = CMTimeGetSeconds(self.player.currentItem.duration);
    if (cur >= duration) {
        if (cur > 0 && duration > 0) {
            return YES;
        }
    }
    return NO;
}

- (void)playedItem {
    
    if (self.state == STOP) {
        return;
    }
    
    self.state = STOP;
    NSLog(@"[PLAY_CONTROL_NOTIFY] STOP");
    if ([self.delegate respondsToSelector:@selector(observeValueForKeyPath:ofObject:)]) {
        [self.delegate observeValueForKeyPath:PlayerStateNotify ofObject:@(self.state)];
    }
}

#pragma mark - AVURLAsset resource loading

- (void)addObserver {
    //NSLog(@"%s",__func__);
    [self.player addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:GAVPlayerRateContext];
    [self.player addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:GAVPlayerItemStatusContext];
    [self.player addObserver:self forKeyPath:@"player.currentItem.rate" options:NSKeyValueObservingOptionNew context:GAVPlayerCurrentItemContext];
}

#pragma mark - As-is

/**
 플레이어 큐
 */
- (dispatch_queue_t)player_q {
    //NSLog(@"%s",__func__);
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

- (id)initWithUrl:(NSString *)url {
    self = [self init];
    if (self) {
        self.streamingUrl = url;
    }
    return self;
}

- (void)play:(BOOL)isStart {
    //NSLog(@"%s",__func__);
    //    [self startUrl:[NSURL fileURLWithPath:_streamingUrl]];
}

- (void)stop {
    NSLog(@"[GAVPLAYER] STOP");
    self.state = STOP;
    if (self.player) {
        @try{
            [self.player removeTimeObserver:self.timeObserverToken];
            self.timeObserverToken = nil;
            
            [self.player removeObserver:self forKeyPath:@"player.rate" context:GAVPlayerRateContext];
            [self.player removeObserver:self forKeyPath:@"player.currentItem.rate" context:GAVPlayerCurrentItemContext];
            [self.player removeObserver:self forKeyPath:@"player.currentItem.status" context:GAVPlayerItemStatusContext];
        }@catch(id anException){
            
        }
        @finally {
            [self.player pause];
            self.player = nil;
        }
    }
}

- (void)pause {
    if (self.state == PAUSE) {
        [self.player play];
        self.state = PLAYING;
        return;
    }
    
    [self.player pause];
    self.state = PAUSE;
    //    [self.player cancelPendingPrerolls];
}

- (void)agrainPlay {
    //NSLog(@"%s",__func__);
}

- (void)moveToSeek:(CGFloat)seekPacket {
    double seek = seekPacket * (double)CMTimeGetSeconds(self.player.currentItem.duration);
    CMTime cmTime = CMTimeMakeWithSeconds(seek, NSEC_PER_SEC);
    [self.player seekToTime:cmTime completionHandler:^(BOOL finished) {
        
    }];
}

-(void)setUpAudioUnitValue:(AudioUnitParameterValue)value AudioEffecGroupType:(struct AudioEffecGroupType)type {
}

-(void)setUpAudioUnitEQValue:(AudioUnitParameterValue)value eQBandNum:(AudioUnitParameterID)num AudioEffecGroupType:(struct AudioEffecGroupType)type {
}

- (BOOL)setUpCurrentTimeTotalPacket:(Float64)totalPacket {
    return 0;
}

#pragma mark - CA Notify

-(void)addObserverTarget:(id)target {
    
    [self removeObserver];
    self.delegate = target;
    @try {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caProcessNotificationStatus:) name:PlayerStateNotify object:@(self.state)];
        
    }@catch (NSException *exception) {
        
    }
}

- (void)removeObserver {
    
    if (!_delegate) {
        return;
    }
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.delegate = nil;
    } @catch (NSException *exception) {
        
    }
}


#pragma mark - Volume

+(void)soundVolume:(Float64)value {
    [WAVPlayer instance].player.volume = value;
}

+(void)soundVolume:(Float64)value :(BOOL)isTemp {
}

+(AudioUnitParameterValue)soundVolume {
    return 0;
}
@end
