//
//  SleepBindJavaScript.m
//  CSleepDolphin
//
//  Created by Start on 2017/9/18.
//  Copyright © 2017年 HET. All rights reserved.
//

#import "SleepBindJavaScript.h"

@implementation SleepBindJavaScript

/**标题和颜色*/
-(void)setTitle:(id)titleName :(id)bg
{
    if (self.setTitleData) {
        self.setTitleData(titleName, bg);
    }
}
/**错误的回调*/
-(void)handleError:(id)errorCode :(id)errorMsg
{
    if (self.handleErrorData) {
        self.handleErrorData(errorCode,errorMsg);
    }
}
/**分享*/
-(void)shareInfo:(id)title :(id)url
{
    if (self.shareInfoData) {
        self.shareInfoData(title, url);
    }
}
/**跳转到积分商城*/
-(void)goIntegraMall
{
    if (self.goIntegraMallData) {
        self.goIntegraMallData();
    }
}
@end
