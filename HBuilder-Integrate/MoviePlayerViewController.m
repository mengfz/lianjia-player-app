//
//  MoviePlayerViewController.m
//  MoviePlayerViewController
//
//  Created by pljhonglu on 13-12-18.
//  Copyright (c) 2013年 pljhonglu. All rights reserved.
//

#import "MoviePlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>
#import "MBProgressHUD.h"

#define TopViewHeight 44
#define BottomViewHeight 50
#define VolumeStep 0.02f
#define BrightnessStep 0.02f
#define MovieProgressStep 5.0f

#define IOS7 ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, GestureType){
    GestureTypeOfNone = 0,
    GestureTypeOfVolume,
    GestureTypeOfBrightness,
    GestureTypeOfProgress,
};
//记住播放进度相关的数据库操作类
@interface DatabaseManager : NSObject
+ (id)defaultDatabaseManager;
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress;
- (CGFloat)getProgressByIdentifier:(NSString *)identifier;
@end

@interface MoviePlayerViewController ()

@property (nonatomic,assign)BOOL isPlaying;
@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)NSMutableArray *itemTimeList;
@property (nonatomic)CGFloat movieLength;
@property (nonatomic)NSInteger currentPlayingItem;
@property (nonatomic,strong)MBProgressHUD *progressHUD;

@property (nonatomic,strong)UIView *topView;
@property (nonatomic,strong)UIButton *returnBtn;
@property (nonatomic,strong)UILabel *titleLable;
@property (nonatomic,strong)UIScrollView *playListView;

@property (nonatomic,strong)UIView *bottomView;
@property (nonatomic,strong)UIButton *playBtn;
@property (nonatomic,strong)UIButton *backwardBtn;
@property (nonatomic,strong)UIButton *forwardBtn;
@property (nonatomic,strong)UIButton *fastBackwardBtn;
@property (nonatomic,strong)UIButton *fastForeardBtn;

@property (nonatomic,strong)UISlider *movieProgressSlider;
@property (nonatomic,strong)UILabel *currentLable;
@property (nonatomic,strong)UILabel *remainingTimeLable;

@property (nonatomic,strong)UIImageView *brightnessView;
@property (nonatomic,strong)UIProgressView *brightnessProgress;

@property (nonatomic,strong)UIView *progressTimeView;
@property (nonatomic,strong)UILabel *progressTimeLable_top;
@property (nonatomic,strong)UILabel *progressTimeLable_bottom;
@property (nonatomic,assign)CGFloat ProgressBeginToMove;

@property (nonatomic,weak)id timeObserver;

@property (nonatomic,assign)GestureType gestureType;

@property (nonatomic,assign)CGPoint originalLocation;

@property (nonatomic,assign)CGFloat systemBrightness;

@property (nonatomic,assign)BOOL isFirstOpenPlayer;//第一次打开需要读取历史观看进度

@property (nonatomic,strong)UIImage *directionImage;//快进快退图片

@property (nonatomic,strong)UIImageView *forwardImageView;
@property (nonatomic,strong)UIImageView *backwardImageView;

@property (nonatomic,strong) UIButton *lockBtn;


@property (nonatomic,assign)BOOL isLock;//锁状态
@property (nonatomic,assign)BOOL playListIsShow;//播放列表的显示状态

@property (nonatomic,assign)BOOL isPortrait;//当前是否为竖屏

@property (nonatomic,assign)BOOL isNetWoking;//当前网络情况

@property (nonatomic,assign)BOOL havePlay;//当前网络情况

@property (nonatomic,assign)int curplayIndex;//当前播放的坐标

@property (nonatomic,strong)NSString *titleText;//播放列表标题


@property (nonatomic,assign)int hidenCount;//隐藏使用






@end

@implementation MoviePlayerViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - init
- (id)initNetworkMoviePlayerViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle{
    
    
    _curplayIndex = 99999;
    self = [super init];

    
    if (self) {
        _isPlaying = YES;
        _isFirstOpenPlayer = NO;
        _movieURL = url;
        _movieURLList = @[url];
        _movieTitle = movieTitle;
        _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = MoviePlayerViewControllerModeNetwork;
    }
    return self;
}

////自定义的初始化的函数
//- (id)initNetworkMoviePlayerViewControllerWithJsonURL:(NSURL *)url{
//    
//
//    self = [super init];
//    
//    _isNetWoking = NO;
//    
//    _havePlay = NO;
//
//    NSMutableArray *playUrlList = [[NSMutableArray alloc] init];
//    NSMutableArray *playNameList = [[NSMutableArray alloc] init];
//    //根据url来获取播放列表
//    NSString *response = @"";
//    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
//    [request startSynchronous];
//    NSError *error = [request error];
//    if (!error) {
//        response = [request responseString];
//        
//        NSRange subRange = NSMakeRange(5,response.length - 6);
//        response = [response  substringWithRange:subRange];
//        
//        
//        if (response == nil) {
//            
//            return nil;
//            
//        }
//        
//        NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
//        
//        NSError *err;
//        
//        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
//                             
//                                                            options:NSJSONReadingMutableContainers
//                             
//                                                              error:&err];
//        if(err) {
//            
//            NSLog(@"json解析失败：%@",err);
//            
//            return self;
//            
//        }
//        
//        NSString *code = [dic objectForKey:@"code"];
//        
//        if ([@"200" isEqualToString:code]) {
//            
//            NSDictionary *resultDict = [dic objectForKey:@"result"];
//            
//            NSArray *chapterList = [resultDict objectForKey:@"chapterList"];
//
//            NSDictionary *lineContentDic = [resultDict objectForKey:@"lineContent"];
//            _titleText = [lineContentDic objectForKey:@"videoName"];
//            //for (int i = 0 ; i< chapterList.count; i ++ ) {
//            for (int i = 0 ; i< 3; i ++ ) {
//                NSDictionary *tempDict =  [chapterList objectAtIndex:i];
////                if(i == 0){
////                    [playUrlList addObject:[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"]];
////                }else{
////                    [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
////
////                }
//                [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
//
//                [playNameList addObject:[tempDict objectForKey:@"name"]];
//            }
//            
//            if (self) {
//                _isPlaying = YES;
//                _isFirstOpenPlayer = NO;
//                _movieURL = playUrlList[0];
//                _movieURLList = playUrlList;
//                _movieTitle = playNameList[0];
//                _movieTitleList = playNameList;
//                _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
//                _mode = MoviePlayerViewControllerModeNetwork;
//                _curplayIndex = 0;
//            }
//            
//            _isNetWoking = YES;
//            
//        }else{
//            NSLog(@"获取数据失败，coode = %@",code);
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络错误" message:@"网络连接失败，请稍后再试!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//            [alertView show];
//            
//            return self;
//
//        }
//        
//
//    }else{
//        NSLog(@"url ==%@ 获取失败",url);
//        
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络错误" message:@"网络连接失败，请稍后再试!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alertView show];
//        
//        return self;
//
//    }
//
//
//    return self;
//}
//自定义的初始化的函数
- (id)initNetworkMoviePlayerViewControllerWithJsonString:(NSString *)jsonString playIndex:(int)playIndex {
    
    self = [super init];
    
    _isNetWoking = NO;
    
    _havePlay = NO;
    
    NSMutableArray *playUrlList = [[NSMutableArray alloc] init];
    NSMutableArray *playNameList = [[NSMutableArray alloc] init];
    
    
    if (jsonString == nil) {
        
        return self;

    }

    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        NSLog(@"json解析失败：%@",err);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
        [alertView show];
        return self;
        
    }
    
    NSDictionary *resultDict = dic;
    
    NSArray *chapterList = [resultDict objectForKey:@"chapterList"];
    
    NSDictionary *lineContentDic = [resultDict objectForKey:@"lineContent"];
    _titleText = [lineContentDic objectForKey:@"videoName"];
    for (int i = 0 ; i< chapterList.count; i ++ ) {
    //for (int i = 0 ; i< 6; i ++ ) {
        NSDictionary *tempDict =  [chapterList objectAtIndex:i];
        //                if(i == 0){
        //                    [playUrlList addObject:[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"]];
        //                }else{
        //                    [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
        //
        //                }
        [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
        
        [playNameList addObject:[tempDict objectForKey:@"name"]];
    }
    
    if (self) {
        _isPlaying = YES;
        _isFirstOpenPlayer = NO;
        _movieURL = playUrlList[0];
        _movieURLList = playUrlList;
        _movieTitle = playNameList[0];
        _movieTitleList = playNameList;
        _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = MoviePlayerViewControllerModeNetwork;
        _curplayIndex = playIndex;
    }
    
    _isNetWoking = YES;
    
    return self;
}


//自定义的初始化的函数
- (id)initNetworkMoviePlayerViewControllerWithChapterList:(NSArray *)chapterList playIndex:(int)playIndex courseName:(NSString *) courseName{
    
    self = [super init];
    
    _isNetWoking = NO;
    
    _havePlay = NO;
    NSMutableArray *playUrlList = [[NSMutableArray alloc] init];
    NSMutableArray *playNameList = [[NSMutableArray alloc] init];

    _titleText = courseName;
    for (int i = 0 ; i< chapterList.count; i ++ ) {
        //for (int i = 0 ; i< 6; i ++ ) {
        NSDictionary *tempDict =  [chapterList objectAtIndex:i];
        //                if(i == 0){
        //                    [playUrlList addObject:[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"]];
        //                }else{
        //                    [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
        //
        //                }
        [playUrlList addObject:[NSURL URLWithString:[tempDict objectForKey:@"path"]]];
        
        [playNameList addObject:[tempDict objectForKey:@"name"]];
    }
    
    if (self) {
        _isPlaying = YES;
        _isFirstOpenPlayer = NO;
        _movieURLList = playUrlList;
        _movieTitleList = playNameList;
        _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = MoviePlayerViewControllerModeNetwork;
        _curplayIndex = playIndex;
    }
    
    _isNetWoking = YES;
    
    return self;
}



- (id)initLocalMoviePlayerViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle{
    self = [super init];
 
    
    if (self) {
        _isPlaying = YES;
        _isFirstOpenPlayer = NO;
        _movieURL = url;
        NSArray *listArray = [[NSArray alloc] initWithObjects:url, nil];
        _movieURLList = listArray;
        _movieTitle = movieTitle;
        _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = MoviePlayerViewControllerModeLocal;
    }
    return self;
}
- (id)initLocalMoviePlayerViewControllerWithURLList:(NSArray *)urlList movieTitle:(NSString *)movieTitle{
    self = [super init];
    if (self) {
        _isPlaying = YES;
        _isFirstOpenPlayer = NO;
        _movieURL = nil;
        _movieURLList = urlList;
        _movieTitle = movieTitle;
        _itemTimeList = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = MoviePlayerViewControllerModeLocal;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    if (self.view.bounds.size.width < self.view.bounds.size.height) {
        _isPortrait = YES;
    }else{
        _isPortrait = NO;
    }
	// Do any additional setup after loading the view.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    self.view.backgroundColor = [UIColor blackColor];
    
    
  
    
    [self createTopView];
    [self createBottomView];
    [self createAvPlayer];
    [self createBrightnessView];
    [self createProgressTimeLable];
    [self createPlayListView];

//    [self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:10];
//    [self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];

    [self.view bringSubviewToFront:_topView];
    [self.view bringSubviewToFront:_bottomView];
    //监控 app 活动状态，打电话/锁屏 时暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    NSUserDefaults *userd = [NSUserDefaults standardUserDefaults];
    if (![userd boolForKey:@"isFirstOpenMoviePlayerViewController"]) {
        //第一次打开，显示引导页
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
        btn.contentMode = UIViewContentModeScaleAspectFill;
        if (self.view.frame.size.height>500) {
            [btn setImage:[UIImage imageNamed:@"player_guide_1136.png"] forState:UIControlStateNormal];
        }else{
            [btn setImage:[UIImage imageNamed:@"player_guide_960.png"] forState:UIControlStateNormal];
        }
        [btn addTarget:self action:@selector(firstCoverOnClick:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:btn];
        [userd setBool:YES forKey:@"isFirstOpenMoviePlayerViewController"];
        [userd synchronize];
        
    }
    UIImage *lockImage = [UIImage imageNamed:@"video_player_unlock.png"];
    
    _lockBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 80, 40, 40)];
    
    if (_isPortrait) {
        _lockBtn.center = CGPointMake(25, self.view.center.y/2);

    }else{
        _lockBtn.center = CGPointMake(25, self.view.center.x/2);

    }
    
    [_lockBtn setBackgroundImage:lockImage forState:UIControlStateNormal];
    
    [self.view addSubview:_lockBtn];
    
    _isLock = NO;
    
    [_lockBtn addTarget:self action:@selector(lockControlBar:) forControlEvents:UIControlEventTouchUpInside];
    
    _hidenCount =  5 ;

    
    NSTimeInterval timeInterval =1.0 ;

    NSTimer *hideTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(handleHiden)
                                                          userInfo:nil
                                                           repeats:YES];


    
//    //锁控制器，但不锁定返回
//    _lockControlBarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_player_lock.png"]];
//    
//    _unlockControlBarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_player_unlock.png"]];
//    
//    [_lockControlBarImageView setHidden:NO];
//
//    [_unlockControlBarImageView setHidden:NO];
//    
//    
//    [_lockControlBarImageView setUserInteractionEnabled:YES];
//    [_unlockControlBarImageView setUserInteractionEnabled:YES];
    
//    [self.view addSubview:_lockControlBarImageView];
//    
//    [self.view addSubview:_unlockControlBarImageView];
//
//    
//    [_lockControlBarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickLock)]];
//    [_lockControlBarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickUnLock)]];

    
}
-(void)handleHiden{
    
    if (_hidenCount > 0) {
        _hidenCount -- ;

    }
    if (_playListIsShow) {
        return;
    }
    if (_hidenCount <=  0) {
        CGRect topFrame = _topView.frame;
        if (topFrame.origin.y>=0) {
            //隐藏上下栏目
             [self hidenControlBar];

        }
        if(_lockBtn.hidden == NO){
            _lockBtn.hidden = YES;
        }

    }
}

-(void)lockControlBar:(id)sender{
    UIImage *lockImage = [UIImage imageNamed:@"video_player_lock.png"];
    UIImage *unLockImage = [UIImage imageNamed:@"video_player_unlock.png"];

    if (!_isLock) {
        [_lockBtn setBackgroundImage:lockImage forState:UIControlStateNormal];
        if (_playListIsShow) {
            [self showPlayListView];
        }
        [self hidenControlBar];

    }else{
        [_lockBtn setBackgroundImage:unLockImage forState:UIControlStateNormal];
        [self showControlBar];
        _hidenCount = 5;
        
    }
    _isLock = !_isLock;
    
    
    //[self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];

}

-(void)hidenLockBtn{
    if (_playListIsShow) {
        return;
    }

    
    _lockBtn.hidden = YES;
}


- (void)viewWillAppear:(BOOL)animated{
    _systemBrightness = [UIScreen mainScreen].brightness;
}

- (void)createAvPlayer{
    
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    CGRect playerFrame = CGRectMake(0, 0, width, height);
    
    __block CMTime totalTime = CMTimeMake(0, 0);
    [_movieURLList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSURL *url = (NSURL *)obj;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        totalTime.value += playerItem.asset.duration.value;
        totalTime.timescale = playerItem.asset.duration.timescale;
        [_itemTimeList addObject:[NSNumber numberWithDouble:((double)playerItem.asset.duration.value/totalTime.timescale)]];
    }];
    _movieLength = (CGFloat)totalTime.value/totalTime.timescale;
    _player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[_curplayIndex]]];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = playerFrame;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    [_player play];
    _currentPlayingItem = 0;
    
    //注册检测视频加载状态的通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [_player.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];




    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //    [_player.currentItem  addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    //这里为了避免timer双重引用引起的内存泄漏
    __weak typeof(_player) player_ = _player;
    __weak typeof(_movieProgressSlider) movieProgressSlider_ = _movieProgressSlider;
    __weak typeof(_currentLable) currentLable_ = _currentLable;
    __weak typeof(_remainingTimeLable) remainingTimeLable_ = _remainingTimeLable;
    __weak typeof(_itemTimeList) itemTimeList_ = _itemTimeList;
    typeof(_movieLength) *movieLength_ = &_movieLength;
    typeof(_gestureType) *gestureType_ = &_gestureType;
    typeof(_currentPlayingItem) *currentPlayingItem_ = &_currentPlayingItem;
    //第一个参数反应了检测的频率
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(3, 30) queue:NULL usingBlock:^(CMTime time){
        if ((*gestureType_) != GestureTypeOfProgress) {
            //获取当前时间
            CMTime currentTime = player_.currentItem.currentTime;
            double currentPlayTime = (double)currentTime.value/currentTime.timescale;
            
            NSInteger currentTemp = *currentPlayingItem_;
            
            while (currentTemp > 0) {
                currentPlayTime += [(NSNumber *)itemTimeList_[currentTemp-1] doubleValue];
                --currentTemp;
            }
            //转成秒数
            
            NSNumber *itemTime = _itemTimeList[_curplayIndex];
            CGFloat remainingTime =  itemTime.floatValue - 0.0f;
            movieProgressSlider_.value = currentPlayTime/(itemTime.floatValue);
            NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:currentPlayTime];
            NSDate *remainingDate = [NSDate dateWithTimeIntervalSince1970:remainingTime];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
            [formatter setDateFormat:(currentPlayTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *currentTimeStr = [formatter stringFromDate:currentDate];
            [formatter setDateFormat:(remainingTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *remainingTimeStr = [NSString stringWithFormat:@"%@",[formatter stringFromDate:remainingDate]];
            
            currentLable_.text = [NSString stringWithFormat:@"%@ / %@",currentTimeStr,remainingTimeStr];
        }
    }];
    
    _progressHUD = [[MBProgressHUD alloc]initWithView:self.view];
    [self.view addSubview:_progressHUD];
    [_progressHUD show:YES];
}
- (void)createTopView{
    
    
    
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    
    
    CGFloat titleLableWidth = 400;
    _topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, TopViewHeight)];
    _topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    
    _returnBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 3, 28, 28)];
//    [_returnBtn setTitle:@"返回" forState:UIControlStateNormal];
    
    UIImage *returnBtnImg = [UIImage imageNamed:@"back.png"];
    [_returnBtn setBackgroundImage:returnBtnImg forState:UIControlStateNormal];

    
    [_returnBtn setTitleColor:[UIColor colorWithRed:0.01f green:0.48f blue:0.98f alpha:1.00f] forState:UIControlStateNormal];
    [_returnBtn addTarget:self action:@selector(popView) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_returnBtn];
    
    _titleLable = [[UILabel alloc]initWithFrame:CGRectMake(width/2-titleLableWidth/2, 0, titleLableWidth, TopViewHeight)];
    _titleLable.backgroundColor = [UIColor clearColor];
    _titleLable.text = [_movieTitleList objectAtIndex:_curplayIndex];
    _titleLable.textColor = [UIColor whiteColor];
    _titleLable.textAlignment = NSTextAlignmentCenter;
    [_topView addSubview:_titleLable];
    
    UIButton *indexBtn = [[UIButton alloc]initWithFrame:CGRectMake(width-35 -10, 0, 35, 35)];
    
    UIImage *playListImg = [UIImage imageNamed:@"playList"];
    [indexBtn setBackgroundImage:playListImg forState:UIControlStateNormal];

    
    [indexBtn addTarget:self action:@selector(showPlayListView) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:indexBtn];

    
//[self.view addSubview:indexBtn];

    [self.view addSubview:_topView];

    
}
- (void)createBottomView{
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    
    
    _bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, height-BottomViewHeight, width, BottomViewHeight)];
    _bottomView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.4f];
    //bottom
    CGFloat bottomOrigin_y = BottomViewHeight - 34;
    // top
    CGFloat marginTop = 13;
    _playBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, bottomOrigin_y -10, 40, 40)];
    [_playBtn setImage:[UIImage imageNamed:@"pause_nor.png"] forState:UIControlStateNormal];
    [_playBtn addTarget:self action:@selector(pauseBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playBtn];
    
    _fastBackwardBtn = [[UIButton alloc]initWithFrame:CGRectMake(_playBtn.frame.origin.x-56-21, marginTop, 21, 16)];
    _fastBackwardBtn.tag = 1;
    [_fastBackwardBtn setImage:[UIImage imageNamed:@"fast_backward_nor.png"] forState:UIControlStateNormal];
    [_fastBackwardBtn addTarget:self action:@selector(fastAction:) forControlEvents:UIControlEventTouchUpInside];
//    [_bottomView addSubview:_fastBackwardBtn];
    
    _fastForeardBtn = [[UIButton alloc]initWithFrame:CGRectMake(_playBtn.frame.origin.x+_playBtn.frame.size.width+56, marginTop, 21, 16)];
    _fastForeardBtn.tag = 2;
    [_fastForeardBtn setImage:[UIImage imageNamed:@"fast_forward_nor.png"] forState:UIControlStateNormal];
    [_fastForeardBtn addTarget:self action:@selector(fastAction:) forControlEvents:UIControlEventTouchUpInside];
//    [_bottomView addSubview:_fastForeardBtn];
    
    _forwardBtn = [[UIButton alloc]initWithFrame:CGRectMake(_fastForeardBtn.frame.origin.x+_fastForeardBtn.frame.size.width+56, marginTop, 16, 16)];
    _forwardBtn.tag = 1;
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateNormal];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateHighlighted
     ];
//    [_bottomView addSubview:_forwardBtn];
    
    _backwardBtn = [[UIButton alloc]initWithFrame:CGRectMake(_fastBackwardBtn.frame.origin.x-56-16, marginTop, 16, 16)];
    _backwardBtn.tag = 2;
    [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateNormal];
    [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateHighlighted];
//    [_bottomView addSubview:_backwardBtn];
    
    if (_datasource) {
        if ([_datasource isHaveNextMovie]) {
            [_forwardBtn setImage:[UIImage imageNamed:@"forward_nor.png"] forState:UIControlStateNormal];
            [_forwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([_datasource isHavePreviousMovie]) {
            [_backwardBtn setImage:[UIImage imageNamed:@"backward_nor.png"] forState:UIControlStateNormal];
            [_backwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    

    _currentLable = [[UILabel alloc]initWithFrame:CGRectMake(63 + width-126 -53 , bottomOrigin_y, 63 + 63, 20)];
    _currentLable.font = [UIFont systemFontOfSize:13];
    _currentLable.textColor = [UIColor whiteColor];
    _currentLable.backgroundColor = [UIColor clearColor];
    _currentLable.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_currentLable];
    
    _movieProgressSlider = [[UISlider alloc]initWithFrame:CGRectMake(63, bottomOrigin_y, width-126 -53, 20)];//height 34
    [_movieProgressSlider setMinimumTrackTintColor:[UIColor whiteColor]];
    [_movieProgressSlider setMaximumTrackTintColor:[UIColor colorWithRed:0.49f green:0.48f blue:0.49f alpha:1.00f]];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    [_bottomView addSubview:_movieProgressSlider];
    
    _remainingTimeLable = [[UILabel alloc]initWithFrame:CGRectMake(width-63, bottomOrigin_y, 63, 20)];
    _remainingTimeLable.font = [UIFont systemFontOfSize:13];
    _remainingTimeLable.textColor = [UIColor whiteColor];
    _remainingTimeLable.backgroundColor = [UIColor clearColor];
    _remainingTimeLable.textAlignment = NSTextAlignmentCenter;
    //[_bottomView addSubview:_remainingTimeLable];
    
    [self.view addSubview:_bottomView];
}
//构建右侧播放列表
-(void)createPlayListView{
    
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    
    //总宽度
    CGFloat titleLableWidth = width/2;
    CGFloat timeLableWidth = 60;

//    _playListView = [[UIView alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2 + 50, TopViewHeight, titleLableWidth, self.view.bounds.size.width-TopViewHeight -BottomViewHeight)];
    _playListView = [[UIScrollView alloc]initWithFrame:CGRectMake(width, TopViewHeight, titleLableWidth, height-TopViewHeight -BottomViewHeight)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleLableWidth,(height-TopViewHeight -BottomViewHeight)/5)];
    
    titleLabel.text= [NSString  stringWithFormat:@"  %@",_titleText];
    
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font =[UIFont boldSystemFontOfSize:18.0f];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    for (int i = 0; i<_movieTitleList.count; i++) {
        //显示名字的button
        UIButton  *lineBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, (height-TopViewHeight -BottomViewHeight)/5*(i+1), titleLableWidth - timeLableWidth,(height-TopViewHeight -BottomViewHeight)/5)];
        
        [lineBtn setTitle:[NSString stringWithFormat:@"    %@",_movieTitleList[i]] forState:UIControlStateNormal];
        [lineBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        lineBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
//        lineBtn.titleLabel.text = _movieTitleList[i];
//      lineBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
//        lineBtn.titleLabel.textColor = [UIColor whiteColor];
        lineBtn.titleLabel.font =[UIFont boldSystemFontOfSize:16.0f];

//        lineBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        lineBtn.tag  = i ;
        [lineBtn addTarget:self action:@selector(clickPlayItem:) forControlEvents:UIControlEventTouchUpInside];
        [_playListView addSubview:lineBtn];

        
        //显示时长的label
        UILabel *timeLable = [[UILabel alloc] initWithFrame:CGRectMake(titleLableWidth - timeLableWidth, (height-TopViewHeight -BottomViewHeight)/5*(i+1), timeLableWidth,(height-TopViewHeight -BottomViewHeight)/5)];
        timeLable.textAlignment = UITextAlignmentLeft;
        [timeLable setFont:[UIFont boldSystemFontOfSize:15.0f]];
        timeLable.textColor = [UIColor whiteColor];
        timeLable.tag = i;
        
        //转为时间
        NSNumber *itemTimeObj =  _itemTimeList[i];
        CGFloat itemTime = itemTimeObj.floatValue;
        NSDate *itemTimeDate = [NSDate dateWithTimeIntervalSince1970:itemTime];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatter setDateFormat:(itemTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
        NSString *itemTimeStr = [NSString stringWithFormat:@"%@",[formatter stringFromDate:itemTimeDate]];
        timeLable.text = itemTimeStr;

        
        
        if(i == _curplayIndex){
            [lineBtn setTitleColor:[UIColor redColor]forState:UIControlStateNormal];
            timeLable.textColor = [UIColor redColor];
        }
        
        [_playListView addSubview:timeLable];

        
    }
    titleLabel.tag = 99999;
    [_playListView addSubview:titleLabel];
    _playListView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    _playListView.scrollEnabled = YES;
    _playListView.contentSize = CGSizeMake(titleLableWidth, (height-TopViewHeight -BottomViewHeight)/5*(_movieTitleList.count+1));
    //增加播放条目
    
    
    
    [self.view addSubview:_playListView];
    
    _playListIsShow = NO;
    
    
}
- (void)createBrightnessView{
    
    
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    
    
    _brightnessView = [[UIImageView alloc]initWithFrame:CGRectMake(width/2-63, height/2-63, 125, 125)];
    _brightnessView.image = [UIImage imageNamed:@"video_brightness_bg.png"];
    
    _brightnessProgress = [[UIProgressView alloc]initWithFrame:CGRectMake(_brightnessView.frame.size.width/2-40, _brightnessView.frame.size.height-30, 80, 10)];
    _brightnessProgress.trackImage = [UIImage imageNamed:@"video_num_bg.png"];
    _brightnessProgress.progressImage = [UIImage imageNamed:@"video_num_front.png"];
    _brightnessProgress.progress = [UIScreen mainScreen].brightness;
    [_brightnessView addSubview:_brightnessProgress];
    [self.view addSubview:_brightnessView];
    _brightnessView.alpha = 0;
}

- (void)createProgressTimeLable{
    
    
    CGFloat height = 0.0f;
    
    CGFloat width = 0.0f;
    
    if (_isPortrait) {
        width = self.view.bounds.size.height;
        
        height = self.view.bounds.size.width;
    }else{
        width = self.view.bounds.size.width;
        
        height = self.view.bounds.size.height;
    }
    

    _progressTimeView = [[UIView alloc]initWithFrame:CGRectMake(width/2-100, height/2-60,260, 280)];
    _progressTimeLable_top = [[UILabel alloc]initWithFrame:CGRectMake(0, 60, 200, 30)];
    _progressTimeLable_top.textAlignment = NSTextAlignmentCenter;
    _progressTimeLable_top.textColor = [UIColor whiteColor];
    _progressTimeLable_top.backgroundColor = [UIColor clearColor];
    _progressTimeLable_top.font = [UIFont systemFontOfSize:20];
    _progressTimeLable_top.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _progressTimeLable_top.shadowOffset = CGSizeMake(1.0, 1.0);
    

    _forwardImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fullscress_duration_advance.png"]];
    
    _forwardImageView.frame = CGRectMake(70, 0, 60, 60);
    //_forwardImageView.center = CGPointMake(self.view.bounds.size.width/2 -95, 0);
    
    _backwardImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fullscress_duration_back.png"]];
    
    _backwardImageView.frame = CGRectMake(70, 0, 60, 60);
    //_backwardImageView.center = CGPointMake(self.view.bounds.size.width/2 -95, 0);
    
    [_progressTimeView addSubview:_forwardImageView];
    [_progressTimeView addSubview:_backwardImageView];
    
    [_backwardImageView setHidden:YES];

    [_forwardImageView setHidden:YES];
    
    
    [_progressTimeView addSubview:_progressTimeLable_top];
    
    
    _progressTimeLable_bottom = [[UILabel alloc]initWithFrame:CGRectMake(0, 90, 200, 30)];
    _progressTimeLable_bottom.textAlignment = NSTextAlignmentCenter;
    _progressTimeLable_bottom.textColor = [UIColor whiteColor];
    _progressTimeLable_bottom.backgroundColor = [UIColor clearColor];
    _progressTimeLable_bottom.font = [UIFont systemFontOfSize:25];
    _progressTimeLable_bottom.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _progressTimeLable_bottom.shadowOffset = CGSizeMake(1.0, 1.0);
    //[_progressTimeView addSubview:_progressTimeLable_bottom];
    
    [self.view addSubview:_progressTimeView];
}
- (void)updateProfressTimeLable{
    NSNumber *curMovieTime = [_itemTimeList objectAtIndex:_curplayIndex];
    double currentTime = floor(curMovieTime.floatValue *_movieProgressSlider.value);
    double changeTime = floor(curMovieTime.floatValue*ABS(_movieProgressSlider.value-_ProgressBeginToMove));
    //转成秒数
    NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:currentTime];
    NSDate *changeDate = [NSDate dateWithTimeIntervalSince1970:changeTime];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    [formatter setDateFormat:(currentTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *currentTimeStr = [formatter stringFromDate:currentDate];
    
    [formatter setDateFormat:(changeTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *changeTimeStr = [formatter stringFromDate:changeDate];
    
    _progressTimeLable_top.text = currentTimeStr;
    _progressTimeLable_bottom.text = [NSString stringWithFormat:@"[%@ %@]",(_movieProgressSlider.value-_ProgressBeginToMove) < 0? @"-":@"+",changeTimeStr];
    
    
    _progressTimeLable_top.text = [NSString stringWithFormat:@"%@  %@",currentTimeStr,_progressTimeLable_bottom.text];
    
    if(_movieProgressSlider.value-_ProgressBeginToMove <0){
        [_backwardImageView setHidden:NO];
        [_forwardImageView setHidden:YES];

    }else{

        [_backwardImageView setHidden:YES];
        [_forwardImageView setHidden:NO];

    }
    
    
}

//显示播放列表
-(void)showPlayListView{
    
    //隐藏->显示
    if(_playListView.tag  == 0){
        //宽度
        CGFloat titleLableWidth = self.view.bounds.size.width/2 ;
        [UIView animateWithDuration:.5 animations:^{
            
            NSLog(@"%f",self.view.bounds.size.width);
            _playListView.frame = CGRectMake(self.view.bounds.size.width/2 , TopViewHeight, titleLableWidth, self.view.bounds.size.height-TopViewHeight -BottomViewHeight);
            _playListView.tag = 999;
        } completion:^(BOOL finished){
            
            
        }];
        
        CGRect topFrame = _topView.frame;
        CGRect bottomFrame = _bottomView.frame;
        if (topFrame.origin.y<0) {
            topFrame.origin.y = 0;
            bottomFrame.origin.y = self.view.frame.size.height-BottomViewHeight;
//            [self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:10];
//            [self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];
            _topView.frame = topFrame;
            _bottomView.frame = bottomFrame;
            _lockBtn.hidden = NO;
        }

        _playListIsShow = YES;
    //显示-> 隐藏
    }else if(_playListView.tag  == 999){
        //宽度
        CGFloat titleLableWidth = self.view.bounds.size.width/2 ;
        [UIView animateWithDuration:.5 animations:^{
            
            NSLog(@"%f",self.view.bounds.size.width);
            _playListView.frame = CGRectMake(self.view.bounds.size.width, TopViewHeight, titleLableWidth, self.view.bounds.size.height-TopViewHeight -BottomViewHeight);
            _playListView.tag = 0;
        } completion:^(BOOL finished){
        }];
        _playListIsShow = NO;
        
//        [self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:10];
//        [self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];

    }

}

-(void)clickPlayItem:(id)sender{
    [_progressHUD show:YES];

    UIButton *btn = (UIButton *)sender;
    
    NSArray *viewsArray = _playListView.subviews;
    
    _curplayIndex = btn.tag;
    
    _movieProgressSlider.value = 0.f;
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];

    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_movieURLList[_curplayIndex] ];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    _titleLable.text = _movieTitleList[_curplayIndex];
    //注册检测视频加载状态的通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_player.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //还原Button字体的颜色
    for (int i = 0; i<viewsArray.count; i++) {
        UIView *v = viewsArray[i];
        if([v isKindOfClass:[UIButton class]]){
            
            UIButton *b = (UIButton *)v;
            [b setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        }else if([v isKindOfClass:[UILabel class]] &&v.tag == btn.tag){
            UILabel *timeLabel = (UILabel *)v;
            timeLabel.textColor = [UIColor redColor];
            
        }else  if([v isKindOfClass:[UILabel class]] ){
            UILabel *timeLabel = (UILabel *)v;
            timeLabel.textColor = [UIColor whiteColor];
        }
        
        
    }
    
    [btn setTitleColor:[UIColor redColor]forState:UIControlStateNormal];

}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        
        if (playerItem.status == AVPlayerStatusReadyToPlay) {
            //视频加载完成,去掉等待
            [_progressHUD hide:YES];
            
            _havePlay = YES;
            
            //获取上次播放进度,仅对本地有效
            if (!_isFirstOpenPlayer) {
                CGFloat progress = [[DatabaseManager defaultDatabaseManager] getProgressByIdentifier:_movieTitle];
                _movieProgressSlider.value = progress;
                _isFirstOpenPlayer = YES;
                [self scrubbingDidEnd];
            }else{
                if (_isPlaying == YES){
                    [_player play];
                }
            }
        }
    }
        if ([keyPath isEqualToString:@"loadedTimeRanges"]){
            float bufferTime = [self availableDuration];
            NSLog(@"缓冲进度%f",bufferTime);
            float durationTime = CMTimeGetSeconds([[_player currentItem] duration]);
            NSLog(@"缓冲进度：%f , 百分比：%f",bufferTime,bufferTime/durationTime);
            
        }
    
    if ( [keyPath isEqualToString:@"playbackBufferEmpty"])
    {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;

        if (playerItem.playbackBufferEmpty) {
            //Your code here
//            [_player pause] ;
            [self pauseBtnClick];
            [_progressHUD show:YES];

        }else{
            [_progressHUD hide:YES];
            [self pauseBtnClick];
        }
    }
    
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;

        if (playerItem.playbackLikelyToKeepUp)
        {
            //Your code here
        }
    }
}
//加载进度
- (float)availableDuration
{
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    }else{
        return 0.0f;
    }
}



#pragma mark - action
/*
 *程序活动的动作
 */
- (void)becomeActive{
    [self pauseBtnClick];
}
/*
 *程序不活动的动作
 */
- (void)resignActive{
    [self pauseBtnClick];
}
//播放/暂停
- (void)pauseBtnClick
{
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
        [_player play];
        [_playBtn setImage:[UIImage imageNamed:@"pause_nor.png"] forState:UIControlStateNormal];
        
    }else{
        [_player pause];
        [_playBtn setImage:[UIImage imageNamed:@"play_nor.png"] forState:UIControlStateNormal];
    }
}
//#define RateStep 0.5
//快退／快进
- (void)fastAction:(UIButton *)btn{
    if (btn.tag == 1) {
        [self movieProgressAdd:-MovieProgressStep];
    }else if (btn.tag == 2){
        [self movieProgressAdd:MovieProgressStep];
    }
}
//上一部／下一部
- (void)forWordOrBackWardMovieAction:(UIButton *)btn{
    _movieProgressSlider.value = 0.f;
    [_progressHUD show:YES];
    //下一部
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    NSDictionary *dic = nil;
    if (btn.tag == 1) {
        dic = [_datasource nextMovieURLAndTitleToTheCurrentMovie];
    }else if(btn.tag == 2){
        dic = [_datasource previousMovieURLAndTitleToTheCurrentMovie];
    }
    _movieURL = (NSURL *)[dic objectForKey:KURLOfMovieDicTionary];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_movieURL];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    _movieTitle = [dic objectForKey:KTitleOfMovieDictionary];
    _titleLable.text = _movieTitle;
    //注册检测视频加载状态的通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    //检测上一部/下一部电影的存在性
    if (_datasource && [_datasource isHaveNextMovie]) {
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_nor.png"] forState:UIControlStateNormal];
        [_forwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateNormal];
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateHighlighted];
        [_forwardBtn removeTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_datasource && [_datasource isHavePreviousMovie]) {
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_nor.png"] forState:UIControlStateNormal];
        [_backwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateNormal];
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateHighlighted];
        [_backwardBtn removeTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

//视频播放到结尾
- (void)playerItemDidReachEnd:(NSNotification *)notification{
    [_progressHUD show:YES];
    
    
    NSArray *viewsArray = _playListView.subviews;
    
    if (_curplayIndex + 1 == _movieURLList.count) {
        [_progressHUD hide:YES];
        return;
    }
    _curplayIndex = _curplayIndex + 1;
    
    _movieProgressSlider.value = 0.f;
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_movieURLList[_curplayIndex] ];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    _titleLable.text = _movieTitleList[_curplayIndex];
    //注册检测视频加载状态的通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [_player.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

    
    //还原Button字体的颜色
    for (int i = 0; i<viewsArray.count; i++) {
        UIView *v = viewsArray[i];
        if([v isKindOfClass:[UIButton class]]&&v.tag == _curplayIndex){
            UIButton *b = (UIButton *)v;
            [b setTitleColor:[UIColor redColor]forState:UIControlStateNormal];

        }else if([v isKindOfClass:[UIButton class]]){
            UIButton *b = (UIButton *)v;
            [b setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
            
        }else if([v isKindOfClass:[UILabel class]] &&v.tag == _curplayIndex){
            UILabel *timeLabel = (UILabel *)v;
            timeLabel.textColor = [UIColor redColor];
            
        }else  if([v isKindOfClass:[UILabel class]] ){
            UILabel *timeLabel = (UILabel *)v;
            timeLabel.textColor = [UIColor whiteColor];
        }
        
    }
    
}
//声音增加
- (void)volumeAdd:(CGFloat)step{
    [MPMusicPlayerController applicationMusicPlayer].volume += step;;
}
//亮度增加
- (void)brightnessAdd:(CGFloat)step{
    [UIScreen mainScreen].brightness += step;
    _brightnessProgress.progress = [UIScreen mainScreen].brightness;
}
//快进／快退
- (void)movieProgressAdd:(CGFloat)step{
    _movieProgressSlider.value += (step/_movieLength);
    [self scrubberIsScrolling];
}
//首次打开引导的点击消失
- (void)firstCoverOnClick:(UIButton *)button{
    [button removeFromSuperview];
}
//返回事件
- (void)popView
{
    NSLog(@"%f",_movieProgressSlider.value);
    if (_havePlay) {
        //保存本次播放进度
        [self pauseBtnClick];

        [[DatabaseManager defaultDatabaseManager] addPlayRecordWithIdentifier:_movieTitle progress:_movieProgressSlider.value];
        
        
        [_player removeTimeObserver:_timeObserver];
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];

        [[self class] cancelPreviousPerformRequestsWithTarget:self];

    }
    

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (_havePlay) {
                self.timeObserver = nil;
                self.player = nil;
                [UIScreen mainScreen].brightness = _systemBrightness;
                if ([_delegate respondsToSelector:@selector(movieFinished:)]) {
                    [_delegate movieFinished:_movieProgressSlider.value];
                }
        }
    }];
}

//按动滑块
-(void)scrubbingDidBegin
{
    _gestureType = GestureTypeOfProgress;
    _ProgressBeginToMove = _movieProgressSlider.value;
    _progressTimeView.hidden = NO;
}
//拖动进度条
-(void)scrubberIsScrolling
{
    if (_mode == MoviePlayerViewControllerModeNetwork) {
        [_progressHUD show:YES];
    }
    NSNumber *currentMoiveLength = [_itemTimeList objectAtIndex:_curplayIndex];
    double currentTime = floor(currentMoiveLength.floatValue *_movieProgressSlider.value);
    
 
    [self updateProfressTimeLable];
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime, 1);
    [_player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish){
         if (_isPlaying == YES){
             [_player play];
             [_progressHUD hide:YES];
         }
     }];
}
//释放滑块
-(void)scrubbingDidEnd
{
    _gestureType = GestureTypeOfNone;
    _progressTimeView.hidden = YES;
    [self scrubberIsScrolling];
}

#pragma mark touch event

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_isLock) {
        return ;

    }

    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.view];
    CGFloat offset_x = currentLocation.x - _originalLocation.x;
    CGFloat offset_y = currentLocation.y - _originalLocation.y;
    if (CGPointEqualToPoint(_originalLocation,CGPointZero)) {
        _originalLocation = currentLocation;
        return;
    }
    _originalLocation = currentLocation;
    
    CGRect frame = [UIScreen mainScreen].bounds;
    if (_gestureType == GestureTypeOfNone) {
        if ((currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y))){            _gestureType = GestureTypeOfVolume;
        }else if ((currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y))){            _gestureType = GestureTypeOfBrightness;
        }else if ((ABS(offset_x) > ABS(offset_y))) {
            _gestureType = GestureTypeOfProgress;
            _progressTimeView.hidden = NO;
        }
    }
    if ((_gestureType == GestureTypeOfProgress) && (ABS(offset_x) > ABS(offset_y))) {
        if (offset_x > 0) {
            //            NSLog(@"横向向右");
            _movieProgressSlider.value += 0.005;
        }else{
            //            NSLog(@"横向向左");
            _movieProgressSlider.value -= 0.005;
        }
        [self updateProfressTimeLable];
    }else if ((_gestureType == GestureTypeOfVolume) && (currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y))){
        if (offset_y > 0){
            [self volumeAdd:-VolumeStep];
        }else{
            [self volumeAdd:VolumeStep];
        }
    }else if ((_gestureType == GestureTypeOfBrightness) && (currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y))){
        if (offset_y > 0) {
            _brightnessView.alpha = 1;
            [self brightnessAdd:-BrightnessStep];
        }else{
            _brightnessView.alpha = 1;
            [self brightnessAdd:BrightnessStep];
        }
    }
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    if (_isLock) {
//        if (_lockBtn.hidden) {
//            _lockBtn.hidden = NO;
//            [self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];
//
//        }
//        return ;
//    }
    
    _originalLocation = CGPointZero;
    _ProgressBeginToMove = _movieProgressSlider.value;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    _hidenCount = 5;


    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    if (_gestureType == GestureTypeOfNone && !CGRectContainsPoint(_bottomView.frame, point) && !CGRectContainsPoint(_topView.frame, point)) {
        //这说明是轻拍收拾，隐藏／现实状态栏
        
        if (_playListIsShow ) {
            return;
        }
        [UIView animateWithDuration:0.5 animations:^{
            CGRect topFrame = _topView.frame;
            CGRect bottomFrame = _bottomView.frame;
            if (topFrame.origin.y<0) {
                //显示
                if (!_isLock) {
                    topFrame.origin.y = 0;
                    bottomFrame.origin.y = self.view.frame.size.height-BottomViewHeight;
                    //[self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:10];

                }
                //[self performSelector:@selector(hidenLockBtn) withObject:nil afterDelay:10];
                _lockBtn.hidden = NO;

            }else{
//                //隐藏
//                topFrame.origin.y = -TopViewHeight;
////                if (!_isLock) {
//                    bottomFrame.origin.y = self.view.frame.size.width;
//
////                }
//                
//                _lockBtn.hidden = YES;
            }

            if (!_isLock) {
                _topView.frame = topFrame;
                _bottomView.frame = bottomFrame;
            }
        }];
    }else if (_gestureType == GestureTypeOfProgress){
        _gestureType = GestureTypeOfNone;
        _progressTimeView.hidden = YES;
        [self scrubberIsScrolling];
    }else{
        _gestureType = GestureTypeOfNone;
        _progressTimeView.hidden = YES;
        if (_brightnessView.alpha) {
            [UIView animateWithDuration:1 animations:^{
                _brightnessView.alpha = 0;
            }];
        }
    }
}

- (void)hidenControlBar{
    if (_playListIsShow) {
        return;
    }
    [UIView animateWithDuration:0.5 animations:^{
//        if (!_isLock) {
            CGRect bottomFrame = _bottomView.frame;
            bottomFrame.origin.y = self.view.frame.size.width;
            _bottomView.frame = bottomFrame;
//        }
        
        CGRect topFrame = _topView.frame;
        topFrame.origin.y = -TopViewHeight;
        _topView.frame = topFrame;
    }];
}

- (void)showControlBar{
    if (_playListIsShow) {
        return;
    }
    [UIView animateWithDuration:0.5 animations:^{
        
        CGRect bottomFrame = _bottomView.frame;
        bottomFrame.origin.y = self.view.frame.size.height-BottomViewHeight;;
        _bottomView.frame = bottomFrame;

        
        CGRect topFrame = _topView.frame;
        topFrame.origin.y = 0;
        _topView.frame = topFrame;
    }];
}

#pragma mark - 系统相关
//隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;//隐藏为YES，显示为NO
}
//横屏
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight );
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

//- (void)dealloc{
//    NSLog(@"dealloc");
//    [super dealloc];
//}
@end


/*
 * DatabaseManager
 * 通过把播放过的影片的进度信息保存在plist 文件中，实现记住播放历史的功能
 * plist 文件采用队列形式，队列长度为50
 */

NSString *const MoviePlayerArchiveKey_identifier = @"identifier";
NSString *const MoviePlayerArchiveKey_date = @"date";
NSString *const MoviePlayerArchiveKey_progress = @"progress";

NSInteger const MoviePlayerArchiveKey_MaxCount = 50;

@implementation DatabaseManager
- (id)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (DatabaseManager *)defaultDatabaseManager{
    static DatabaseManager *manager = nil;
    if (manager == nil) {
        manager = [[DatabaseManager alloc]init];
    }
    return manager;
}
+ (NSString *)pathOfArchiveFile{
    NSArray *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [filePath lastObject];
    NSString *plistFilePath = [documentPath stringByAppendingPathComponent:@"playRecord.plist"];
    return plistFilePath;
}
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress{
    
    NSMutableArray *recardList = [[NSMutableArray alloc]initWithContentsOfFile:[DatabaseManager pathOfArchiveFile]];
    if (!recardList) {
        recardList = [[NSMutableArray alloc]init];
    }
    if (recardList.count==MoviePlayerArchiveKey_MaxCount) {
        [recardList removeObjectAtIndex:0];
    }
    
    NSDictionary *dic = @{MoviePlayerArchiveKey_identifier:identifier,MoviePlayerArchiveKey_date:[NSDate date],MoviePlayerArchiveKey_progress:@(progress)};
    [recardList addObject:dic];
    [recardList writeToFile:[DatabaseManager pathOfArchiveFile] atomically:YES];
}

- (CGFloat)getProgressByIdentifier:(NSString *)identifier{
    NSMutableArray *recardList = [[NSMutableArray alloc]initWithContentsOfFile:[DatabaseManager pathOfArchiveFile]];
    __block CGFloat progress = 0;
    [recardList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dic = obj;
        if ([dic[MoviePlayerArchiveKey_identifier] isEqualToString:identifier]) {
            progress = [dic[MoviePlayerArchiveKey_progress] floatValue];
            *stop = YES;
        }
    }];
    if (progress > 0.9 || progress < 0.05) {
        return 0;
    }
    return progress;
}




@end