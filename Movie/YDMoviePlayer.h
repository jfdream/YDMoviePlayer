//
//  YDMoviePlayer.h
//  YDMoviePlayer
//
//  Created by jfdream on 15/12/16.
//  Copyright © 2015年 jfdream. All rights reserved.
//  version 1.0.0

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class YDMoviePlayer;
@protocol YDMoviePlayerDelegate <NSObject>

@optional
-(void)moviePlayerDidPrepareToPlay:(YDMoviePlayer *)player;
-(void)moviePlayerDidFailedToPlayer:(YDMoviePlayer *)player error:(NSError *)error;
-(void)moviePlayerDidEndToPlay:(YDMoviePlayer *)player;
-(void)moviePlayerDidChangeStatus:(YDMoviePlayer *)player withStatus:(BOOL)notBuffering;
-(void)moviePlayerPlayWithError:(NSString *)errorReason withPlayer:(YDMoviePlayer *)player;
-(void)moviePlayerCurrentPlaybackTime:(double)currentTime withDuration:(double)duration;
-(void)moviePlayerSeekDidOver:(YDMoviePlayer *)player withSuccess:(BOOL)success;

@end

@interface YDMoviePlayer : NSObject
-(instancetype)initWithURL:(NSURL *)videoURL;

@property (nonatomic,weak)id <YDMoviePlayerDelegate>delegate;
@property (nonatomic,readonly)UIView * playerView;

//支持seek
@property (nonatomic)NSTimeInterval currentTime;
@property (nonatomic,readonly)NSTimeInterval duration;

@property (nonatomic)BOOL autoStartWhenPrapared;//准备好后自动播放
@property (nonatomic,readonly)BOOL isPlaying;

/*
 *  brief 是否监听当前播放时间变化的回调，YES的话会产生当前播放时间变化的回调，使用代理的方式给出
 */
-(void)play;
-(void)pause;
-(void)shutdown;
-(void)setVolume:(double)volume;

@end
