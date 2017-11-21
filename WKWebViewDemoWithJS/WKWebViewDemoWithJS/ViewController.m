//
//  ViewController.m
//  WKWebViewDemoWithJS
//
//  Created by Start on 2017/9/19.
//  Copyright © 2017年 het. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "SleepBindJavaScript.h"

@protocol SleepBindJavaScriptDelegate <NSObject>

@optional
//获取H5 协议字符串，根据字符串 APP做不同业务
-(void)sleepWebViewDelegateString:(NSString *)protolString;
@end

@interface ViewController ()<WKNavigationDelegate,WKScriptMessageHandler,WKUIDelegate>
/**wkWebView*/
@property(nonatomic,strong)WKWebView *wkWebView;
@property (nonatomic, strong) NSMutableDictionary* javascriptInterfaces;
@property(nonatomic,strong)SleepBindJavaScript *bindJavaScript;
@property(nonatomic,weak) id<SleepBindJavaScriptDelegate> SleepWkWebViewDelegate;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupSubViews];
    
}
#pragma mark - 初始化
-(void)setupSubViews
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    self.bindJavaScript = [[SleepBindJavaScript alloc]init];
    [self addJavascriptInterfaces:self.bindJavaScript WithName:@"SleepBindJavaScript"];
    [config.userContentController addScriptMessageHandler:self name:@"SleepBindJavaScript"];
    self.wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
    self.wkWebView.UIDelegate = self;
    self.wkWebView.navigationDelegate = self;
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:urlStr];
    [self.wkWebView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    [self.view addSubview:self.wkWebView];
    //调用方法的回调
    self.bindJavaScript.setTitleData = ^(id titleName, id bg) {
        NSLog(@"titleName%@,bg=%@",titleName,bg);
    };
    self.bindJavaScript.handleErrorData = ^(id errorCode, id errorMsg) {
         NSLog(@"errorCode%@,errorMsg=%@",errorCode,errorMsg);
    };
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"消息名:%@", message.name);
    NSLog(@"消息内容:%@", message.body);
    NSObject* interface = [self.javascriptInterfaces objectForKey:message.name];
    if(interface)
    {
        
        NSArray *components = [message.body componentsSeparatedByString:@"&"];
        NSString  *func=[components objectAtIndex:0];
        NSString* methodStr = [[func componentsSeparatedByString:@"="]objectAtIndex:1];
        NSString *method;
        unsigned int mc = 0;
        Class cls = object_getClass(interface);
        Method * mlist = class_copyMethodList(cls, &mc);
        for (int i = 0; i < mc; i++){
            
            NSString *methodName=[NSString stringWithUTF8String:sel_getName(method_getName(mlist[i]))];
            //NSLog(@"methodName:%@,%@",methodName,methodStr);
            if([methodName hasPrefix:methodStr])
            {
                //if([methodName rangeOfString:method].length)
                // {
                method=methodName;
                //NSLog(@"获取到的methodName:%@,%@,%@",methodName,methodStr,method);
                //break;
            }
        }
        
        free(mlist);
        
        // execute the interfacing method
        SEL selector = NSSelectorFromString(method);
        NSMethodSignature* sig = [[interface class] instanceMethodSignatureForSelector:selector];
        if(sig == nil)
        {
            return ; //  判断方法是否存在，若不存在则返回空
        }
        NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
        invoker.selector = selector;
        invoker.target = interface;
        NSMutableArray* args = [[NSMutableArray alloc] init];
        if ([components count] > 1){
            for (int j = 0;j< components.count-1; j++){
                NSString* argStr = ((NSString*) [components objectAtIndex:j + 1]);
                NSArray* formattedArgs = [argStr componentsSeparatedByString:@"="];
                NSString* formattedArgStr = ((NSString*) [formattedArgs objectAtIndex:1]);
                NSString* arg = [formattedArgStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [args addObject:arg];
                [invoker setArgument:&arg atIndex:(j + 2)];
            }
        }
        [invoker invoke];
    }

}

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name{
    if (! self.javascriptInterfaces){
        self.javascriptInterfaces = [[NSMutableDictionary alloc] init];
    }
    [self.javascriptInterfaces setValue:interface forKey:name];

}
//去掉空格
- (NSString *)removeSpaceAndNewline:(NSString *)str
{
    NSString *temp = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *text = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
    return text;
}
//字典转为json数据
- (NSString *)toJsonStringWithDictionary:(NSDictionary *)dictionary{
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&err];
    if (err) {
        return nil;
    }
    NSString * json = [[NSString alloc] initWithData:jsonData
                                            encoding:NSUTF8StringEncoding];
    return json;
}
#pragma mark - WKNavigationDelegate
// 开始导航跳转时会回调
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"开始跳转");
}
// 导航失败时会回调
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // 类似 UIWebView 的- webView:didFailLoadWithError:
    NSLog(@"跳转失败");
}
// 导航完成时，会回调（也就是页面载入完成了）
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation { // 类似 UIWebView 的 －webViewDidFinishLoad:
    NSLog(@"页面加载完成");
    NSDictionary *dataJson = @{@"code":@100,@"description":@"未登录，获取token",@"data":@{@"accessToken":@"1111"}};
    NSString *dataStr =[self convertToJsonData:dataJson];
    NSString *setJsonData = [NSString stringWithFormat:@"setJsonData('%@')",dataStr];
    [self.wkWebView evaluateJavaScript:setJsonData completionHandler:^(id _Nullable value, NSError * _Nullable error) {
        NSLog(@"error: %@",error);
    }];
}

- (NSString *)dictionaryToJson:(NSDictionary *)dic {
    
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}
- (NSString *)convertToJsonData:(NSDictionary *)dict{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    //替换掉网址的\转义    \/  替换为 /
    
    [mutStr replaceOccurrencesOfString:@"\\/" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0,mutStr.length)];
    
    return mutStr;
    
}




// 类型，在请求先判断能不能跳转（请求） 请求开始前，会先调用此代理方法
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
   // 类似 UIWebView 的 -webView: shouldStartLoadWithRequest: navigationType:
    NSString *requestString =[[navigationAction.request URL]absoluteString];
    
    NSLog(@"requestString:%@",requestString);
    if([requestString hasPrefix:@"http"]||[requestString hasPrefix:@"file://"])
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else
    {
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
        //        if(self.SleepWkWebViewDelegate && [self.SleepWkWebViewDelegate respondsToSelector:@selector(sleepWebViewDelegateString:)])
        //        {
        //            [self.SleepWkWebViewDelegate sleepWebViewDelegateString:requestString];
        //        }
        //拿到不同的字符串去跳转不同的界面...
    }
    
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@"%s", __FUNCTION__);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:[NSString stringWithFormat:@"%@",message] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    NSLog(@"%s", __FUNCTION__);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"confirm" message:[NSString stringWithFormat:@"%@",message] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    NSLog(@"%s", __FUNCTION__);
    
    NSLog(@"%@", prompt);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"textinput" message:[NSString stringWithFormat:@"%@",prompt] preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
