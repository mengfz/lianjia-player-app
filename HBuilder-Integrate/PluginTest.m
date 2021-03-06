//
//  PluginTest.m
//  HBuilder-Hello
//
//  Created by Mac Pro on 14-9-3.
//  Copyright (c) 2014年 DCloud. All rights reserved.
//

#import "PluginTest.h"
#import "MoviePlayerViewController.h"
#import "DownloadNav.h"
#import "DownloadListController.h"
#import "FilesDownManage.h"
#import "AppDelegate.h"
#import "FMDatabase.h"
#import "PlayRecordViewController.h"

@implementation PGPluginTest
//调出播放器
- (void)PluginTestFunction:(PGMethod*)commands
{
	if ( commands ) {
    
//        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
//        NSString* cbId = [commands.arguments objectAtIndex:0];
//        
//        // 用户的参数会在第二个参数传回
//        NSString* pArgument1 = [commands.arguments objectAtIndex:1];
//        NSString* pArgument2 = [commands.arguments objectAtIndex:2];
//        NSString* pArgument3 = [commands.arguments objectAtIndex:3];
//        NSString* pArgument4 = [commands.arguments objectAtIndex:4];
//        
//        // 如果使用Array方式传递参数
//        NSArray* pResultString = [NSArray arrayWithObjects:pArgument1, pArgument2, pArgument3, pArgument4, nil];
//        
//        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
//        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray: pResultString];
//
//        // 如果Native代码运行结果和预期不同，需要通过回调通知JS层出现错误，并返回错误提示
//        //PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsString:@"惨了! 出错了！ 咋(wu)整(liao)"];
//
//        // 通知JS层Native层运行结果
//        [self toCallback:cbId withReslut:[result toJSONString]];
//        NSURL *url = [[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"];
//        
//        NSData *orgFileData = [NSData dataWithContentsOfURL:url ];
//        NSData *resultData = [orgFileData subdataWithRange:NSMakeRange(16, orgFileData.length -16)];
//        
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *filePath = [NSString stringWithFormat:@"%@/1_tmp.mp4",documentsDirectory];
//        
//        [resultData writeToFile:filePath atomically:YES];
//        
//        filePath = [NSString stringWithFormat:@"file://%@",filePath];
//        
//        url = [NSURL URLWithString:filePath];
//        MoviePlayerViewController *movieVC = [[MoviePlayerViewController alloc]initLocalMoviePlayerViewControllerWithURL:url movieTitle:@"电影名称1"];
//        [self presentViewController:movieVC animated:YES completion:nil];
//        [movieVC release];
        
        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
        
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.firstFlag = nil;
        
        
        NSString* cbId = [commands.arguments objectAtIndex:1];
        
        NSString *userId = [commands.arguments objectAtIndex:3];
        
        NSString *flag = [commands.arguments objectAtIndex:4];
        
        [self openDBwithUserId:userId];

        //打开播放记录
        if ([@"playrecord" isEqualToString:flag]) {
            
            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]];
            
            UINavigationController *playRecordcontroller = [story instantiateViewControllerWithIdentifier:@"playRecord"];
            
            [self presentViewController:playRecordcontroller animated:YES completion:nil];

            return;
        }
        
        //删除下载的文件
        if ([@"delete" isEqualToString:flag]) {
            //先删除数据库的记录:先删除小节，如果小节对应的课程下没有了小节，则将课程删除
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSFileManager* fm = [NSFileManager defaultManager];
            
            NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
            NSString*documentsDirectory =[paths objectAtIndex:0];
            FilesDownManage *filedownmanage = [FilesDownManage sharedFilesDownManage];
            
            [filedownmanage startLoad];
            //删除已经下载的
            NSString *queryDownloadIds = [NSString stringWithFormat:@"SELECT ID  FROM CHAPTER_LIST WHERE DOWNLOAD_FINISH = '2'"];
            FMResultSet *rs1 =[appDelegate.db executeQuery:queryDownloadIds];
            [appDelegate.db beginTransaction];
            while ([rs1 next]) {
                NSString* deleteId = [rs1 stringForColumn:@"ID"];
                
                
                NSString *getInfoSql = [NSString stringWithFormat:@"SELECT FILE_NAME ,COURSE_ID FROM CHAPTER_LIST WHERE ID='%@'",deleteId];
                
                NSString *fileName = @"";
                NSString *courseID = @"";
                
                FMResultSet *rs =[appDelegate.db executeQuery:getInfoSql];
                while ([rs next]) {
                    fileName = [rs stringForColumn:@"FILE_NAME"];
                    courseID = [rs stringForColumn:@"COURSE_ID"];
                }
                
                
                NSString *filePath = [NSString stringWithFormat:@"%@/%@/DownLoad/dest/%@",documentsDirectory,appDelegate.userId,fileName];
                NSLog(@"正在删除文件的filePath = %@",filePath);
                
                

                NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM CHAPTER_LIST WHERE ID = '%@'",deleteId];
                NSLog(@"删除小节的sql == %@",deleteSql);
                [appDelegate.db executeUpdate:deleteSql];
                if ([fm fileExistsAtPath:filePath]) {
                    [fm removeItemAtPath:filePath error:nil];
                }
                
                int chapterCount = 0;
                NSString *selectCourseCount  = [NSString stringWithFormat:@"SELECT COUNT(1) TOTAL FROM CHAPTER_LIST WHERE  COURSE_ID = '%@'",courseID];
                
                NSLog(@"查询小节所在课程下的小节数量 sql == %@",selectCourseCount);
                
                rs =[appDelegate.db executeQuery:selectCourseCount];
                
                if ([rs next]) {
                    chapterCount = [rs intForColumn:@"TOTAL"];
                }
                if(chapterCount == 0){
                    deleteSql = [NSString stringWithFormat:@"DELETE FROM COURSE_LIST WHERE ID = '%@'",courseID];
                    NSLog(@"查询小节所在课程的 sql == %@",selectCourseCount);
                    [appDelegate.db executeUpdate:deleteSql];
                    
                }
            }
            [FilesDownManage sharedFilesDownManage].finishedlist = [NSMutableArray array];
            [appDelegate.db commit];
            //删除正在下载的
            
            
            NSMutableArray *deleteRequests = [NSMutableArray array];
            NSMutableArray *downingList =[FilesDownManage sharedFilesDownManage].downinglist;
            MidHttpRequest *executeingRequest = nil;

            for (int i = 0; i < downingList.count; i++) {
                MidHttpRequest *tr = [downingList objectAtIndex:i];
                if ([tr isExecuting]) {
                    executeingRequest = tr;
                }else{
                    [deleteRequests addObject:tr];
                }
                
            }
            if (executeingRequest != nil) {
                [deleteRequests addObject:executeingRequest];
            }
            while ([deleteRequests count] > 0) {
                [[FilesDownManage sharedFilesDownManage] deleteRequest:[deleteRequests objectAtIndex:0]];
                [deleteRequests removeObjectAtIndex:0];
            }
            //删除播放记录
            NSString *deleteRecord1 = [NSString stringWithFormat:@"DELETE FROM PLAY_LOCAL_RECORDS"];
            
            NSString *deleteRecord2 = [NSString stringWithFormat:@"DELETE FROM PLAY_RECORDS"];
            [appDelegate.db beginTransaction];
            [appDelegate.db executeUpdate:deleteRecord1];
            [appDelegate.db executeUpdate:deleteRecord2];
            [appDelegate.db commit];

            return;
        }

        

        
  
        
        if (cbId == nil || [@""  isEqualToString:cbId]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
            NSLog(@"没有传入参数");
            
            [alertView show];
        }else{
            
            NSString* playIndexId = [commands.arguments objectAtIndex:2] ;

            

            
            NSData *jsonData = [cbId dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *err = nil;
            
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                 
                                                                options:NSJSONReadingMutableContainers
                                 
                                                                  error:&err];
            
            if (dic == nil || [dic count] == 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
                [alertView show];
                return;

            }
            
            
            NSDictionary *resultDict = dic;
            
            NSArray *chapterList = [resultDict objectForKey:@"chapterList"];
            
            NSDictionary *lineContentDic = [resultDict objectForKey:@"lineContent"];
            NSString *courseName = [lineContentDic objectForKey:@"videoName"];
            NSString *courseId = [lineContentDic objectForKey:@"id"];
            NSString *imgPath = [lineContentDic objectForKey:@"videoUrl"];

            
            int playIndex = 99999;
            for (int i = 0; i< [chapterList count]; i++) {
                NSDictionary *lineDict = [chapterList objectAtIndex:i];
                if ([playIndexId isEqualToString:[lineDict objectForKey:@"id"]]) {
                    playIndex = i;

                }
            }
            if (playIndex == 99999) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }

            
//            MoviePlayerViewController *movieVC = [[MoviePlayerViewController alloc]initNetworkMoviePlayerViewControllerWithJsonString:cbId playIndex:playIndex];
            MoviePlayerViewController *movieVC = [[MoviePlayerViewController alloc]initNetworkMoviePlayerViewControllerWithChapterList:chapterList playIndex:playIndex courseName:courseName courseId:courseId imgPath:imgPath];
            [self presentViewController:movieVC animated:YES completion:nil];
            [movieVC release];
            
        }
        

        
        
//        NSURL *jsonUrl = [NSURL URLWithString:@"http://app.ljabc.com.cn/app/classRoom/getCourseByCourseId.html?courseId=783"];
//        
//        
//        MoviePlayerViewController *movieVC = [[MoviePlayerViewController alloc]initNetworkMoviePlayerViewControllerWithJsonURL:jsonUrl];
//        [self presentViewController:movieVC animated:YES completion:nil];
//        [movieVC release];
        
    }
}

//打开下载管理界面
- (void)PluginTestFunctionArrayArgu:(PGMethod*)commands
{
    if ( commands ) {
        
        
//        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
//        NSString* cbId = [commands.arguments objectAtIndex:0];
//        
//        // 用户的参数会在第二个参数传回，可以按照Array方式传入，
//        NSArray* pArray = [commands.arguments objectAtIndex:1];
//        
//        // 如果使用Array方式传递参数
//        NSString* pResultString = [NSString stringWithFormat:@"%@ %@ %@ %@",[pArray objectAtIndex:0], [pArray objectAtIndex:1], [pArray objectAtIndex:2], [pArray objectAtIndex:3]];
//        
//        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
//        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:pResultString];
//        
//        // 如果Native代码运行结果和预期不同，需要通过回调通知JS层出现错误，并返回错误提示
//        //PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsString:@"惨了! 出错了！ 咋(wu)整(liao)"];
//        
//        // 通知JS层Native层运行结果
//        [self toCallback:cbId withReslut:[result toJSONString]];
        
        //--------------------------------------------------------------------------
//        NSArray* array = [commands.arguments objectAtIndex:1] ;
//        NSString *cbId = [array objectAtIndex:0];
//        if (cbId == nil || [@""  isEqualToString:cbId]) {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
//            NSLog(@"没有传入参数");
//
//            [alertView show];
//            return;
//        }else{
//            
////            NSString* playIndexStr = [commands.arguments objectAtIndex:2];
////            int playIndex = playIndexStr.intValue;
//            
//            NSData *jsonData = [cbId dataUsingEncoding:NSUTF8StringEncoding];
//            
//            NSError *err = nil;
//            
//            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
//                                 
//                                                                options:NSJSONReadingMutableContainers
//                                 
//                                                                  error:&err];
//            
//            if (dic == nil || [dic count] == 0) {
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
//                [alertView show];
//                return;
//                
//            }
//            
//            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]];
//
//            DownloadNav *downloadNav = [story instantiateViewControllerWithIdentifier:@"DownloadNav"];
//            NSArray *controllers = downloadNav.viewControllers;
//            
//            DownloadListController* dlc = [controllers objectAtIndex:0];
//            [dlc initDownLoadDataWithDic:dic];
//            
//            
//            [self presentViewController:downloadNav animated:YES completion:nil];
//            
//
//            [downloadNav release];
//            
//        }

            NSArray *parmArray = [commands.arguments objectAtIndex:1];
            NSString *userId = [parmArray objectAtIndex:0];
        
        
            [self openDBwithUserId:userId];
            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]];

            DownloadNav *downloadNav = [story instantiateViewControllerWithIdentifier:@"DownloadNav"];
            NSArray *controllers = downloadNav.viewControllers;
//            FilesDownManage *filesDownManage=[FilesDownManage sharedFilesDownManage];
//            if (!filesDownManage.basepath) {
                [FilesDownManage sharedFilesDownManageWithBasepath:[NSString stringWithFormat:@"%@/%@",userId,@"DownLoad"] TargetPathArr:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/%@",userId,@"DownLoad/dest"]]];
//            }
        
            //删除所有过期的视频文件
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSFileManager* fm = [NSFileManager defaultManager];
        
        NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString*documentsDirectory =[paths objectAtIndex:0];
        
        //实例化一个NSDateFormatter对象
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //设定时间格式,这里可以设置成自己需要的格式
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        //用[NSDate date]可以获取系统当前时间
        NSString *today = [dateFormatter stringFromDate:[NSDate date]];
        

        
        NSString *querySql = [NSString stringWithFormat:@"SELECT ID,FILE_NAME,COURSE_ID,EFFECTIVE_TIME FROM CHAPTER_LIST WHERE DOWNLOAD_FINISH =2 "];

        FMResultSet *rs = [appDelegate.db executeQuery:querySql];
        

        [appDelegate.db beginTransaction];

        while (rs.next) {
            //先删除数据库的记录:先删除小节，如果小节对应的课程下没有了小节，则将课程删除
            
            NSString *fileName = [rs stringForColumn:@"FILE_NAME"];
            NSString *courseID = [rs stringForColumn:@"COURSE_ID"];
            NSString *effectiveTime = [rs stringForColumn:@"EFFECTIVE_TIME"];
            NSString *deleteId = [rs stringForColumn:@"ID"];
        
            
            if ([effectiveTime  compare:today] == NSOrderedDescending || [effectiveTime isEqualToString:@"永久"]) {
                continue;
            }
            

            NSString *filePath = [NSString stringWithFormat:@"%@/%@/DownLoad/dest/%@",documentsDirectory,appDelegate.userId,fileName];
            NSLog(@"正在删除文件的filePath = %@",filePath);
            
            
            NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM CHAPTER_LIST WHERE ID = '%@'",deleteId];
            NSLog(@"删除小节的sql == %@",deleteSql);
            [appDelegate.db executeUpdate:deleteSql];
            if ([fm fileExistsAtPath:filePath]) {
                [fm removeItemAtPath:filePath error:nil];
            }
            
            int chapterCount = 0;
            NSString *selectCourseCount  = [NSString stringWithFormat:@"SELECT COUNT(1) TOTAL FROM CHAPTER_LIST WHERE  COURSE_ID = '%@'",courseID];
            
            NSLog(@"查询小节所在课程下的小节数量 sql == %@",selectCourseCount);
            
            FMResultSet *rs1 =[appDelegate.db executeQuery:selectCourseCount];
            
            if ([rs1 next]) {
                chapterCount = [rs1 intForColumn:@"TOTAL"];
            }
            if(chapterCount == 0){
                deleteSql = [NSString stringWithFormat:@"DELETE FROM COURSE_LIST WHERE ID = '%@'",courseID];
                NSLog(@"查询小节所在课程的 sql == %@",selectCourseCount);
                [appDelegate.db executeUpdate:deleteSql];
                
            }
            
            
        }
        [appDelegate.db commit];


        
        
            [self presentViewController:downloadNav animated:YES completion:nil];
//        [self getHaveDownloadInDB:@"783"];


            //[downloadNav release];
        
    }
}
//启动下载任务
- (void)PluginTestFunctionArrayArgu1:(PGMethod*)commands
{
    if ( commands ) {
        
        //        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
        //        NSString* cbId = [commands.arguments objectAtIndex:0];
        //
        //        // 用户的参数会在第二个参数传回，可以按照Array方式传入，
        //        NSArray* pArray = [commands.arguments objectAtIndex:1];
        //
        //        // 如果使用Array方式传递参数
        //        NSString* pResultString = [NSString stringWithFormat:@"%@ %@ %@ %@",[pArray objectAtIndex:0], [pArray objectAtIndex:1], [pArray objectAtIndex:2], [pArray objectAtIndex:3]];
        //
        //        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
        //        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:pResultString];
        //
        //        // 如果Native代码运行结果和预期不同，需要通过回调通知JS层出现错误，并返回错误提示
        //        //PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsString:@"惨了! 出错了！ 咋(wu)整(liao)"];
        //
        //        // 通知JS层Native层运行结果
        //        [self toCallback:cbId withReslut:[result toJSONString]];
        
        
        NSArray* array = [commands.arguments objectAtIndex:1] ;
        NSString *cbId = [array objectAtIndex:0];
        NSString *cbId1 = [array objectAtIndex:1];
        NSString *userId = [array objectAtIndex:2];

        [self openDBwithUserId:userId];
        
        if (cbId == nil || [@""  isEqualToString:cbId]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
            NSLog(@"没有传入参数");
            
            [alertView show];
            return;
        }else{
            
            //            NSString* playIndexStr = [commands.arguments objectAtIndex:2];
            //            int playIndex = playIndexStr.intValue;
            
            NSData *jsonData = [cbId dataUsingEncoding:NSUTF8StringEncoding];
            
            NSData *jsonData1 = [cbId1 dataUsingEncoding:NSUTF8StringEncoding];

            //NSArray *downloadArray = [cbId1 componentsSeparatedByString:@","];
            
            
            NSError *err = nil;
            
            NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                 
                                                                options:NSJSONReadingMutableContainers
                                 
                                                                  error:&err];
            
            NSMutableDictionary *dic1 = [NSJSONSerialization JSONObjectWithData:jsonData1
                                        
                                                                       options:NSJSONReadingMutableContainers
                                        
                                                                         error:&err];
            
            
            dic1 = [dic1 objectForKey:@"effectiveTime"];
            
            NSMutableArray *idArray = [NSMutableArray array];
            NSMutableArray *etArray = [NSMutableArray array];

            if ([dic1 count] > 0) {
                idArray = [dic1 allKeys];
            }
            
            for (int i = 0; i < [idArray count]; i++) {
                [etArray addObject:[dic1 objectForKey:[idArray objectAtIndex:i]]];
            }

            
           NSArray *chapterList = [dic objectForKey:@"chapterList"];
            
          
            
            
            NSMutableArray *resultArray = [NSMutableArray array];
            
            for (int i = 0 ; i < chapterList.count; i++) {
                NSDictionary *lineDict = [chapterList objectAtIndex:i];
                if ([idArray containsObject:[lineDict objectForKey:@"id"]]) {
                    [lineDict  setValue:[etArray objectAtIndex:[idArray indexOfObject:[lineDict objectForKey:@"id"]]] forKey:@"effectiveTime"];
                    [resultArray addObject:lineDict];
                }
                
            }
            
            [dic setValue:resultArray forKey:@"chapterList"];
            
            if (dic == nil || [dic count] == 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"参数错误" message:@"传入参数错误！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
                [alertView show];
                return;
                
            }
            [FilesDownManage sharedFilesDownManageWithBasepath:[NSString stringWithFormat:@"%@/%@",userId,@"DownLoad"] TargetPathArr:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/%@",userId,@"DownLoad/dest"]]];
            [[FilesDownManage sharedFilesDownManage] downFileWithDict:dic];
            
          
        }
        
        
    }
}
- (NSData*)PluginTestFunctionSync:(PGMethod*)command
{
    // 根据传入获取参数
    NSString* pArgument1 = [command.arguments objectAtIndex:0];//userId
    NSString* pArgument2 = [command.arguments objectAtIndex:1];//courseid

    
    
    [self openDBwithUserId:pArgument1];

    NSMutableArray *retArray = [NSMutableArray array];
    NSString *querySql = @"";
    if(pArgument2 == nil ||[@"" isEqualToString:pArgument2]){
        querySql = [NSString stringWithFormat:@"SELECT ID FROM CHAPTER_LIST "];
    }else{
        querySql = [NSString stringWithFormat:@"SELECT ID FROM CHAPTER_LIST WHERE COURSE_ID= '%@'",pArgument2];
    }

    NSLog(@"查询已经下载过的在数据库里记录的sql ==%@",querySql);
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    
    FMResultSet *rs = [appDelegate.db executeQuery:querySql];
    while ([rs next]) {
        [retArray addObject:[rs  stringForColumn:@"ID"]];
    }

    return [self resultWithJSON:retArray];

}


- (NSData*)PluginTestFunctionSyncArrayArgu:(PGMethod*)command
{
    // 根据传入参数获取一个Array，可以从中获取参数
    NSArray* pArray = [command.arguments objectAtIndex:0];
    
    // 创建一个作为返回值的NSDictionary
    NSDictionary* pResultDic = [NSDictionary dictionaryWithObjects:pArray forKeys:[NSArray arrayWithObjects:@"RetArgu1",@"RetArgu2",@"RetArgu3", @"RetArgu4", nil]];

    // 返回类型为JSON，JS层在取值是需要按照JSON进行获取
    return [self resultWithJSON: pResultDic];
}
- (void)playLocalMovieList{
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"2" withExtension:@"mp4"];
    NSURL *url3 = [[NSBundle mainBundle] URLForResource:@"3" withExtension:@"mp4"];
    NSArray *list = @[url1,url2,url3];
    MoviePlayerViewController *movieVC = [[MoviePlayerViewController alloc]initLocalMoviePlayerViewControllerWithURLList:list movieTitle:@"电影名称3"];
    [self presentViewController:movieVC animated:YES completion:nil];
}
- (BOOL)isHavePreviousMovie{
    return NO;
}
- (BOOL)isHaveNextMovie{
    return NO;
}
- (NSDictionary *)previousMovieURLAndTitleToTheCurrentMovie{
    return nil;
}
- (NSDictionary *)nextMovieURLAndTitleToTheCurrentMovie{
    return nil;
}
-(void)openDBwithUserId:(NSString *)userId{
    //检查document/db目录下数据库文件是否存在，如果不存在，则从boundle目录拷贝1个过去
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];


    if(![userId isEqualToString:appDelegate.userId] && appDelegate.userId !=nil && [@"" isEqualToString: appDelegate.userId]){
        [appDelegate.db  close];
        
    }
    
    if (![userId isEqualToString: appDelegate.userId]) {
        NSFileManager*fileManager =[NSFileManager defaultManager];
        NSError*error;
        NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString*documentsDirectory =[paths objectAtIndex:0];
        
        NSString*destPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",userId,@"player.db"]];
        

        
        NSLog(@"db destPath=%@",destPath);
        
        if (![fileManager fileExistsAtPath:destPath]) {
           NSString*destDirPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",userId]];
            
            [fileManager createDirectoryAtPath:destDirPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString* sourcePath =[[NSBundle mainBundle] pathForResource:@"player" ofType:@"db"];
            [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error ];
        }
         //打开数据库
        appDelegate.db = [FMDatabase databaseWithPath:destPath];
        [appDelegate.db open];
        appDelegate.userId = userId;
    }

}

//查询已经入库的视频记录
-(NSString *)getHaveDownloadInDB:(NSString *)courseId{
    NSMutableString *returnStr = [NSMutableString string];
    
    NSString *querySql = [NSString stringWithFormat:@"SELECT ID FROM CHAPTER_LIST WHERE COURSE_ID= '%@'",courseId];
    
    NSLog(@"查询已经下载过的在数据库里记录的sql ==%@",querySql);
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    
    FMResultSet *rs = [appDelegate.db executeQuery:querySql];
    while ([rs next]) {
        [returnStr appendString:[NSString stringWithFormat:@"%@,",[rs stringForColumn:@"ID"]]];
    }
    
    if ([returnStr length]>0) {
        returnStr = [returnStr substringToIndex:[returnStr length]-1];
    }
    
    return returnStr;
    
}

@end
