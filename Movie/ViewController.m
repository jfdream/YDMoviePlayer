//
//  ViewController.m
//  Movie
//
//  Created by jfdreamyang on 05/10/2016.
//  Copyright © 2016 jfdreamyang. All rights reserved.
//

#import "ViewController.h"
#import "YDMoviePlayer.h"

@interface ViewController ()
{
    YDMoviePlayer * _moviePlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _moviePlayer=[[YDMoviePlayer alloc]initWithURL:[NSURL URLWithString:@"http://192.168.2.102/hello.mp4"]];
    _moviePlayer.playerView.frame=CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width*9/16.0);
    [self.view addSubview:_moviePlayer.playerView];
    
    _moviePlayer.autoStartWhenPrapared=YES;
    
    UIButton * button=[UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    button.frame=CGRectMake(100, 300, 100, 100);
    button.backgroundColor=[UIColor redColor];
    [self.view addSubview:button];
}
-(void)buttonClick{
    [_moviePlayer.playerView removeFromSuperview];
    [_moviePlayer shutdown];
    _moviePlayer=[[YDMoviePlayer alloc]initWithURL:[NSURL URLWithString:@"http://192.168.2.102/hello.mp4"]];
    _moviePlayer.playerView.frame=CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width*9/16.0);
    [self.view addSubview:_moviePlayer.playerView];
    _moviePlayer.autoStartWhenPrapared=YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
