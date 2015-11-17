//
//  ViewController.m
//  avplayer
//
//  Created by ouzhenxuan on 15/10/29.
//  Copyright © 2015年 ouzhenxuan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+SUImage.h"

#define DEVICE_WIDTH [UIScreen mainScreen].bounds.size.width
#define device_height [UIScreen mainScreen].bounds.size.height

@interface ViewController ()
{
    BOOL isPlaying;
    UISlider *_movieProgressSlider;
    CGFloat  totalMovieDuration;
    UIProgressView  *_progressView;
    
    
    UIActivityIndicatorView * videoLoding;      //视频缓冲
    UIImageView * videoPlay;
    int recordCurrentTime;
    
    IBOutlet UILabel * showTheTime ;                     //显示快进快退的时间
    NSString * originalTime;                    //原始时间
}
@property (retain, nonatomic) UISlider *movieProgressSlider;
@property (retain, nonatomic) UIProgressView  *progressView;
@property (strong,nonatomic) MPMoviePlayerController * moviePlayer;
@end

@implementation ViewController
@synthesize progressView = _progressView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString * url = @"http://ouzhenxuan.file.alimmdn.com/560a4ced60b258073cc75269/ios1444120900.jpg?t=1444120909931";
    
    NSURL *sourceMovieURL = [NSURL URLWithString:url];
    
    //使用playerItem获取视频的信息，当前播放时间，总时间等
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:sourceMovieURL];
    //player是视频播放的控制器，可以用来快进播放，暂停等
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_cusromPlayer.player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [_cusromPlayer setPlayer:player];
    [_cusromPlayer.player play];
    isPlaying = YES;
    
    [_cusromPlayer.player.currentItem addObserver:self forKeyPath:@"status"
                                                           options:NSKeyValueObservingOptionNew
                                                           context:nil];
    [_cusromPlayer.player.currentItem  addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_cusromPlayer.player.currentItem];
    
    
    
    CMTime totalTime = playerItem.duration;
    //因为slider的值是小数，要转成float，当前时间和总时间相除才能得到小数,因为5/10=0
    totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:totalMovieDuration];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (totalMovieDuration/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }
    else
    {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    NSLog(@"totalMovieDuration:%@",showtimeNew);
    //在totalTimeLabel上显示总时间
    self.lab.text = showtimeNew;
    
    [self monitorMovieProgress];
    
    
    UITapGestureRecognizer *oneTap=nil;
    oneTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(oneTap:)];
    oneTap.numberOfTapsRequired = 1;
    [_cusromPlayer addGestureRecognizer:oneTap];
    
    UIPanGestureRecognizer *panTheVideo=nil;
    panTheVideo=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panTheVieoView:)];
    [_cusromPlayer addGestureRecognizer:panTheVideo];
    
}

#pragma mark - 视频页面拖动处理
- (void) panTheVieoView:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    CGFloat firstX = 0.0;
    //    CGFloat firstY = 0.0;
    
    if ([(UIPanGestureRecognizer *)recognizer state] == UIGestureRecognizerStateBegan) {
        recordCurrentTime = floor(totalMovieDuration * self.movieProgressSlider.value);
        //        originalTime = [self secondToTime:recordCurrentTime];
        originalTime = [self secondToTime:totalMovieDuration];
        showTheTime.hidden = NO;
    }
    
    if ([(UIPanGestureRecognizer *)recognizer state] == UIGestureRecognizerStateChanged) {
        CGFloat x = firstX + translatedPoint.x;
        //        CGFloat y = firstX + translatedPoint.y;
        
        
        
        CGFloat precent =  x /DEVICE_WIDTH;         //获取移动的百分比
        CGFloat panToTime = recordCurrentTime + totalMovieDuration * precent;       //移动到第几秒
        int intpanToTime = floorf(panToTime);
        if (intpanToTime<0) {
            intpanToTime = 0;
        }else if (intpanToTime>totalMovieDuration){
            intpanToTime = totalMovieDuration;
        }
        
        //秒数转换为时间
        NSString * showtimeNew = [self secondToTime:intpanToTime];
        NSLog(@"totalMovieDuration:%@",showtimeNew);
        
        //转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime = CMTimeMake(intpanToTime, 1);
        [_cusromPlayer.player seekToTime:dragedCMTime completionHandler:
         ^(BOOL finish)
         {
             if (isPlaying == YES)
             {
                 [_cusromPlayer.player play];
             }
         }];
        
        showTheTime.text = [NSString stringWithFormat:@"%@ / %@",showtimeNew,originalTime];
    }
    
    if (([(UIPanGestureRecognizer *)recognizer state] == UIGestureRecognizerStateEnded) || ([(UIPanGestureRecognizer *)recognizer state] == UIGestureRecognizerStateCancelled)) {
        CGFloat x = recognizer.view.center.x;
        CGFloat y = recognizer.view.center.y;
        NSLog(@"x:%f  y:%f",x,y);
        
        showTheTime.hidden = YES;
    }
    
}


//秒转化为时间
- (NSString *)secondToTime :(int)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }
    else
    {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

-(void)moviePlayDidEnd:(NSNotification*)notification{
    //视频播放完成
    double currentTime = floor(totalMovieDuration *0);
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime, 1);
    [_cusromPlayer.player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish)
     {
         isPlaying = NO;
         [_cusromPlayer.player pause];
     }];
}

- (void) oneTap:(UITapGestureRecognizer *)sender
{
    if (isPlaying == YES)
    {
        isPlaying = NO;
        [_cusromPlayer.player pause];
    }
    else
    {
        isPlaying = YES;
        [_cusromPlayer.player play];
    }
}

#pragma mark - 处理视频加载完毕，缓冲处理，还有网络不好的情况。
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status==AVPlayerStatusReadyToPlay) {
            //视频加载完成

            //计算视频总时间
            CMTime totalTime = playerItem.duration;
            totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
            NSDate *d = [NSDate dateWithTimeIntervalSince1970:totalMovieDuration];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            if (totalMovieDuration/3600 >= 1) {
                [formatter setDateFormat:@"HH:mm:ss"];
            }
            else
            {
                [formatter setDateFormat:@"mm:ss"];
            }
            NSString *showtimeNew = [formatter stringFromDate:d];
            self.lab.text = showtimeNew;

        }else {
            //网络不好，飞行模式的时候处理错误
            [self.cusromPlayer.player pause];
            [self.cusromPlayer.player setRate:0];
            
            [self.cusromPlayer.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
            [self.cusromPlayer.player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
            [self.cusromPlayer.player replaceCurrentItemWithPlayerItem:nil];
            totalMovieDuration = 0;
            //            self.cusromPlayer.player.currentItem = nil;
            self.cusromPlayer.player = nil;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self.cusromPlayer.player.currentItem cancelPendingSeeks];
            [self.cusromPlayer.player.currentItem.asset cancelLoading];
            
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"网络不好" message:@"请检查网络配置" delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
            [alertView show];
            
        }
    }
    if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        float bufferTime = [self availableDuration];
        NSLog(@"缓冲进度%f",bufferTime);
        float durationTime = CMTimeGetSeconds([[_cusromPlayer.player currentItem] duration]);
        [self.progressView setProgress:bufferTime/durationTime animated:YES];
    }
    
}

//加载进度
- (float)availableDuration
{
    NSArray *loadedTimeRanges = [[_cusromPlayer.player currentItem] loadedTimeRanges];
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}


-(void)monitorMovieProgress{
//    [self.Moviebuffer startAnimating];
    //使用movieProgressSlider反应视频播放的进度
    //第一个参数反应了检测的频率
    [_cusromPlayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
        //获取当前时间
        CMTime currentTime = _cusromPlayer.player.currentItem.currentTime;
        //转成秒数
        CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
        _movieProgressSlider.value = currentPlayTime/totalMovieDuration;
        NSString * showtime = [self secondToTime:totalMovieDuration];
        self.lab.text = showtime;
    }];
    
    //左右轨的图片
    UIImage *stetchLeftTrack = [[UIImage imageFromColor:[UIColor redColor] frame:CGRectMake(0, 0, 1, 12)]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    UIImage *stetchRightTrack = [[UIImage imageFromColor:[UIColor clearColor] frame:CGRectMake(0, 0, 1, 12)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    //滑块图片
    UIImage *thumbImage = [UIImage imageFromColor:[UIColor clearColor] frame:CGRectMake(0, 0, 1, 12)];
    

    self.movieProgressSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, DEVICE_WIDTH + 64-12, DEVICE_WIDTH, 12)];
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, DEVICE_WIDTH +64 -7 , DEVICE_WIDTH, 12)];
    
    self.progressView.transform = CGAffineTransformMakeScale(1.0f,6.0f);
    
    _progressView.progressTintColor = [UIColor colorWithWhite:1 alpha:0.2];
    _progressView.trackTintColor = [UIColor clearColor];
    [self.progressView setProgress:0 animated:NO];
    [self.view addSubview:_progressView];
    
    [self.view addSubview:self.movieProgressSlider];
    [self.movieProgressSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
    [self.movieProgressSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
    self.movieProgressSlider.backgroundColor = [UIColor clearColor];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [self.movieProgressSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
    [self.movieProgressSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [self.movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [self.movieProgressSlider addTarget:self action:@selector(scrubberIsScrolling) forControlEvents:UIControlEventValueChanged];
    [self.movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
}

//快进
-(void)scrubberIsScrolling
{
    double currentTime = floor(totalMovieDuration *self.movieProgressSlider.value);
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime, 1);
    [_cusromPlayer.player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish)
     {
         if (isPlaying == YES)
         {
             [_cusromPlayer.player play];
         }
     }];
}

//按动滑块
-(void)scrubbingDidBegin
{
    [_cusromPlayer.player pause];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)scrubbingDidEnd
{
    
}

@end
