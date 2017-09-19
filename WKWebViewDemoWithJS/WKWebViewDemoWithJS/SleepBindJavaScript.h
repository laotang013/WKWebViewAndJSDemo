//
//  SleepBindJavaScript.h
//  CSleepDolphin
//
//  Created by Start on 2017/9/18.
//  Copyright © 2017年 HET. All rights reserved.
//

#import <Foundation/Foundation.h>
/**设置标题和颜色*/
typedef void (^SetTitleData)(id titleName,id bg);
/**错误的回调*/
typedef void (^HandleErrorData)(id errorCode,id errorMsg);
/**分享*/
typedef void (^ShareInfoData)(id title,id url);
/**跳转到商城*/
typedef void (^GoIntegraMallData)();
@interface SleepBindJavaScript : NSObject
@property(nonatomic,copy)SetTitleData setTitleData;
@property(nonatomic,copy)HandleErrorData handleErrorData;
@property(nonatomic,copy)ShareInfoData shareInfoData;
@property(nonatomic,copy)GoIntegraMallData goIntegraMallData;
@end
