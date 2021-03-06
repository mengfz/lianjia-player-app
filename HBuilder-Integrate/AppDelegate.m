//
//  AppDelegate.m
//  Pandora
//
//  Created by Mac Pro_C on 12-12-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "PDRCore.h"
#import "PDRCommonString.h"
#import "PluginTest.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Reachability.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation AppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark app lifecycle



- (void)startServer
{
    // Start the server (and check for problems)
    
    NSError *error;
    if([httpServer start:&error])
    {
        self.port = [httpServer listeningPort];
        
        DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
    }
    else
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }
}
/*
 * @Summary:程序启动时收到push消息
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    
    

    
    //检查document/db目录下数据库文件是否存在，如果不存在，则从boundle目录拷贝1个过去

//    NSFileManager*fileManager =[NSFileManager defaultManager];
//    NSError*error;
//    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//    NSString*documentsDirectory =[paths objectAtIndex:0];
//    
//    NSString*destPath =[documentsDirectory stringByAppendingPathComponent:@"player.db"];
//    
//    NSLog(@"db destPath=%@",destPath);
//    
//    if (![fileManager fileExistsAtPath:destPath]) {
//        NSString* sourcePath =[[NSBundle mainBundle] pathForResource:@"player" ofType:@"db"];
//        [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error];
//    }
//    
//    //打开数据库
//    self.db = [FMDatabase databaseWithPath:destPath];
//
//    [_db open];
    
    
//    //创建视频文件下载目录 document/downloads
//    
//    NSString *downloadsPath = [NSString stringWithFormat:@"%@/downloads",documentsDirectory];
//    NSLog(@"创建的下载目录%@",downloadsPath);
//    BOOL isDir = TRUE;
//    if (![fileManager fileExistsAtPath:downloadsPath isDirectory:&isDir]) {
//        [fileManager  createDirectoryAtPath:downloadsPath withIntermediateDirectories:YES attributes:nil error:&error];
//    }else{
//        NSLog(@"downloadsPath exists");
//    }
    // To keep things simple and fast, we're just going to log to the Xcode console.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Create server using our custom MyHTTPServer class
    httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [httpServer setType:@"_http._tcp."];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *webPath = documentsDirectory;
    DDLogInfo(@"Setting document root: %@", webPath);
    
    [httpServer setDocumentRoot:webPath];
    
    [self startServer];
    

    BOOL ret = [PDRCore setLaunchOptions:launchOptions];
    [[PDRCore Instance] load];
    
    NSURL  *url = [NSURL URLWithString:@"http://127.0.0.1:54856/mengfanzhen/DownLoad/dest/bigvideo.mp4"];
//
//    NSURL  *url = [NSURL URLWithString:@"http://localhost:8080/mcs/html/bigvideo.mp4"];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        NSLog(@"%lld",playerItem.asset.duration.value);
    
    AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:url options:nil];
    
    CMTime audioDuration = audioAsset.duration;
    
    float audioDurationSeconds =CMTimeGetSeconds(audioDuration);
    NSLog(@"%f",audioDurationSeconds);
    
    
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    
    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA
    //reach.reachableOnWWAN = NO;
    
    // Here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(reachabilityChanged:)
//                                                 name:kReachabilityChangedNotification
//                                               object:nil];
//    
//    [reach startNotifier];

    
    return ret;
}
-(void)reachabilityChanged:(NSNotification *)notification{
    
    Reachability *reach = [notification object];
    
    if([reach isKindOfClass:[Reachability class]]){
        
        NetworkStatus status = [reach currentReachabilityStatus];
        
        if(status == 0){
            
        }else if (status == 1){
            
        }else if (status == 2){
        }
        NSLog(@"status=========%d",status);
        
        //Insert your code here
        
    }
    
}
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void(^)(BOOL succeeded))completionHandler{
    [PDRCore handleSysEvent:PDRCoreSysEventPeekQuickAction withObject:shortcutItem];
    completionHandler(true);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{

    [httpServer stop];
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventEnterBackground withObject:nil];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
        [self startServer];
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventEnterForeGround withObject:nil];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[PDRCore Instance] unLoad];
}

#pragma mark -
#pragma mark URL

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    [self application:application handleOpenURL:url];
    return YES;
}

/*
 * @Summary:程序被第三方调用，传入参数启动
 *
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventOpenURL withObject:url];
    return YES;
}


#pragma mark -
#pragma mark APNS
/*
 * @Summary:远程push注册成功收到DeviceToken回调
 *
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevDeviceToken withObject:deviceToken];
}

/*
 * @Summary: 远程push注册失败
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRegRemoteNotificationsError withObject:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:userInfo];
}

/*
 * @Summary:程序收到本地消息
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:notification];
}


- (void)dealloc
{
    [super dealloc];
}

@end
