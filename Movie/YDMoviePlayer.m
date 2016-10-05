//
//  YDMoviePlayer.m
//  YDMoviePlayer
//
//  Created by jfdream on 15/12/16.
//  Copyright © 2015年 jfdream. All rights reserved.
//

#import "YDMoviePlayer.h"

NSString * YDMovieStatus=@"status";
NSString * YDMovieRate=@"rate";
NSString * YDMoviePlayerItem=@"currentItem";
NSString * YDMovieDuration=@"duration";
NSString * YDMovieLoadTimeRange=@"currentItem.loadedTimeRanges";


typedef enum : NSUInteger {
    YDPlayerStatusPlay,
    YDPlayerStatusPause,
    YDPlayerStatusPlayStop,
    YDPlayerStatusToEnd
} YDPlayerStatus;


@interface VideoPlayerView : UIView
@property (nonatomic,readonly)AVPlayerLayer * playerLayer;
@end

@implementation VideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
-(AVPlayerLayer *)playerLayer
{
    //将layer转换AVPlayerLayer，从这里可以往该layer上面添加player
    return (AVPlayerLayer *)self.layer;
}
@end


@interface YDMoviePlayer ()
@property (nonatomic,strong)AVAsset * asset;//视频资源
@property (nonatomic,strong)AVPlayerItem * playerItem;

@end

@implementation YDMoviePlayer
{
    VideoPlayerView * _playerView;
    AVPlayer * player;
    NSURL * videoURL;
    NSTimer * observerTimeTimer;
    //通过该属性控制视频的播放和暂停，代码级别
    YDPlayerStatus playerStatus;
}
- (instancetype)initWithURL:(NSURL *)_videoURL
{
    self = [super init];
    if (self) {
        _playerView=[[VideoPlayerView alloc]initWithFrame:CGRectZero];
        _playerView.backgroundColor=[UIColor lightGrayColor];
        _duration=0.f;
        videoURL=_videoURL;
        
        __weak YDMoviePlayer * weakSelf=self;
        NSArray * keys=@[@"playable",@"tracks"];//监听视频的状态
        _asset=[AVURLAsset URLAssetWithURL:videoURL options:nil];
        [_asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //切回主线程刷新数据UI
                [weakSelf checkVideoAvailableAndStart:keys];
                
                if ([weakSelf.delegate respondsToSelector:@selector(moviePlayerDidPrepareToPlay:)]) {
                    [weakSelf.delegate moviePlayerDidPrepareToPlay:weakSelf];
                }
                
            });
        }];
        
        
        
    }
    return self;
}
-(NSTimeInterval)currentTime
{
    CMTime currentCMTime=player.currentTime;
    return CMTimeGetSeconds(currentCMTime);;
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:YDMovieStatus]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
        switch (status) {
            case AVPlayerStatusUnknown: {
                break;
            }
            case AVPlayerStatusReadyToPlay: {
                if (self.autoStartWhenPrapared) {
                    playerStatus=YDPlayerStatusPlay;
                    [player play];
                }
                break;
            }
            case AVPlayerStatusFailed: {
                break;
            }
        }
        if ([self.delegate respondsToSelector:@selector(moviePlayerDidChangeStatus:withStatus:)]) {
            [self.delegate moviePlayerDidChangeStatus:self withStatus:_isPlaying];
        }
    }
    else if ([keyPath isEqualToString:YDMovieDuration]) {
        //可以获取duration
        CMTime duration=player.currentItem.duration;
        if (CMTIME_IS_VALID(duration)==NO) {
            _duration=0.f;
            return;
        }
        _duration=CMTimeGetSeconds(duration);
    }
    else if ([keyPath isEqualToString:YDMoviePlayerItem]) {
        //播放的item是否发生变化
        //        AVPlayerItem *aPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        [self stopObserveCurrentTime];
        [self startObserveCurrentTime];
        
    }
    else if ([keyPath isEqualToString:YDMovieRate])
    {
        if (player.rate==0.f) {
            _isPlaying=NO;
        }
        else
        {
            _isPlaying=YES;
        }
        if ([self.delegate respondsToSelector:@selector(moviePlayerDidChangeStatus:withStatus:)]) {
            [self.delegate moviePlayerDidChangeStatus:self withStatus:_isPlaying];
        }
    }
}
-(void)shouldContinueToPlay
{
    if ([self.delegate respondsToSelector:@selector(moviePlayerCurrentPlaybackTime:withDuration:)]) {
        [self.delegate moviePlayerCurrentPlaybackTime:self.currentTime withDuration:self.duration];
    }
    if (playerStatus==YDPlayerStatusPlay&&_isPlaying==NO&&player.currentItem.loadedTimeRanges.count>=1) {
        NSValue * canPlayValue=player.currentItem.loadedTimeRanges[0];
        CMTimeRange timeRange = [canPlayValue CMTimeRangeValue];
        double canPlayDuration=CMTimeGetSeconds(timeRange.duration);
        double startSec=CMTimeGetSeconds(timeRange.start);
        if ((canPlayDuration+startSec-2)>self.currentTime) {
            [player play];
        }
    }
}
-(AVPlayer *)player
{
    return player;
}
-(void)startObserveCurrentTime
{
    [observerTimeTimer invalidate];
    observerTimeTimer=[NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(shouldContinueToPlay) userInfo:nil repeats:YES];
    [observerTimeTimer fire];
}
-(void)stopObserveCurrentTime
{
    [observerTimeTimer invalidate];
    observerTimeTimer=nil;
}
-(void)checkVideoAvailableAndStart:(NSArray *)keys
{
    if (_asset.playable==NO) {
        if ([self.delegate respondsToSelector:@selector(moviePlayerDidFailedToPlayer:error:)]) {
            [self.delegate moviePlayerDidFailedToPlayer:self error:nil];
        }
        return;
    }
    //核查播放器中正常播放需要的某些核心值
    for (NSString *key in keys) {
        NSError *error = nil;
        AVKeyValueStatus status = [_asset statusOfValueForKey:key error:&error];
        if (status == AVKeyValueStatusFailed || status == AVKeyValueStatusCancelled) {
            if ([self.delegate respondsToSelector:@selector(moviePlayerDidFailedToPlayer:error:)]) {
                [self.delegate moviePlayerDidFailedToPlayer:self error:error];
            }
            return;
        }
    }
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:YDMovieStatus];
        [self.playerItem removeObserver:self forKeyPath:YDMovieDuration];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    self.playerItem=[AVPlayerItem playerItemWithAsset:_asset];
    [self.playerItem addObserver:self
                      forKeyPath:YDMovieStatus
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:nil];
    
    // Durationchange
    [self.playerItem addObserver:self
                      forKeyPath:YDMovieDuration
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidPlayToEndTime)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    if (!player) {
        player=[AVPlayer playerWithPlayerItem:self.playerItem];
        // Observe currentItem, catch the -replaceCurrentItemWithPlayerItem:
        [player addObserver:self
                 forKeyPath:YDMoviePlayerItem
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:nil];
        
        // Observe rate, play/pause-button?
        [player addObserver:self
                 forKeyPath:YDMovieRate
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:nil];
    }
    if (player.currentItem != self.playerItem) {
        [player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    _playerView.playerLayer.player=player;
}
-(void)playerItemDidPlayToEndTime
{
    playerStatus=YDPlayerStatusToEnd;
    [player pause];
    if ([self.delegate respondsToSelector:@selector(moviePlayerDidEndToPlay:)]) {
        [self.delegate moviePlayerDidEndToPlay:self];
    }
}
-(void)closeAudio
{
    player.volume=0.f;
}
-(void)setVolume:(double)volume
{
    player.volume=volume;
}
-(void)shutdown
{
    [observerTimeTimer invalidate];
    observerTimeTimer=nil;
    [player removeObserver:self forKeyPath:YDMovieRate context:nil];
    [player removeObserver:self forKeyPath:YDMoviePlayerItem context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.playerItem removeObserver:self forKeyPath:YDMovieDuration context:nil];
    [self.playerItem removeObserver:self forKeyPath:YDMovieStatus context:nil];
    
    [_playerView removeFromSuperview];
    [_playerView.layer removeFromSuperlayer];
    _playerView.playerLayer.player=nil;
    _playerView=nil;
    player=nil;
}
-(void)dealloc{

}
-(void)setCurrentTime:(NSTimeInterval)currentTime
{
    CMTime seekTime=CMTimeMakeWithSeconds(currentTime, 30);
    __weak YDMoviePlayer * weakSelf=self;
    [player seekToTime:seekTime completionHandler:^(BOOL finished) {
        if ([weakSelf.delegate respondsToSelector:@selector(moviePlayerSeekDidOver:withSuccess:)]) {
            [weakSelf.delegate moviePlayerSeekDidOver:self withSuccess:finished];
        }
    }];
}
-(void)play
{
    playerStatus=YDPlayerStatusPlay;
    if (player.rate==0.f) {
        [player play];
    }
}
-(void)pause
{
    playerStatus=YDPlayerStatusPause;
    [player pause];
}
-(UIView *)playerView
{
    return _playerView;
}

@end
