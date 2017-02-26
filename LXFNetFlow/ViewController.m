//
//  ViewController.m
//  LXFNetFlow
//
//  Created by 蓝潇枫 on 2017/2/26.
//  Copyright © 2017年 lanxiaofeng. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"

#include <ifaddrs.h>
#include <net/if.h>

@interface ViewController ()
//上行速度Label
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
//下行速度Label
@property (weak, nonatomic) IBOutlet UILabel *downLabel;
//监测网络状态类
@property (nonatomic, strong) Reachability *reachability;
//记录上一秒的网速
@property (assign, nonatomic) float preWWAN_R;
@property (assign, nonatomic) float preWWAN_S;
@property (assign, nonatomic) float preWifi_R;
@property (assign, nonatomic) float preWifi_S;
//定时器
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化实例变量
    _preWifi_R = 0.0;
    _preWifi_S = 0.0;
    _preWWAN_R = 0.0;
    _preWWAN_S = 0.0;
    _reachability = [Reachability reachabilityWithHostName:@"hha"];
    
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(refreshV) userInfo:nil repeats:YES];
//    self.timer = timer;
    //    CADisplayLink* link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshV)];
    //    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    //    link.frameInterval = 60;
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"disOver");
    //移除定时器
    [self.timer invalidate];
    self.timer = nil;
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    NSLog(@"ove");
    //移除定时器
    if (self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


/**
 开始监控
 */
- (IBAction)begin:(UIButton *)sender {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(refreshV) userInfo:nil repeats:YES];
    self.timer = timer;
}

/**
 结束监控
 */
- (IBAction)end:(UIButton *)sender {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)refreshV {
//    NSLog(@"定时器调用了");
    // 上行、下行流量
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        float wifiS_preSecond = [[self getDataCounters][0] floatValue] - _preWifi_S;
        float wifiR_preSecond = [[self getDataCounters][1] floatValue] - _preWifi_R;
        _topLabel.text = [NSString stringWithFormat:@"%.0f KB/s", wifiS_preSecond];
        _downLabel.text = [NSString stringWithFormat:@"%.0f KB/s", wifiR_preSecond];
    }else if(_reachability.currentReachabilityStatus == ReachableViaWWAN) {
        float wwanS_preSecond = [[self getDataCounters][2] floatValue] - _preWWAN_S;
        float wwanR_preSecond = [[self getDataCounters][3] floatValue] - _preWWAN_R;
        _topLabel.text = [NSString stringWithFormat:@"%.0f KB/s", wwanS_preSecond];
        _downLabel.text = [NSString stringWithFormat:@"%.0f KB/s", wwanR_preSecond];
    }else {
        
    }
    [self currentLiuLiang];
}

// 赋值当前流量
- (void)currentLiuLiang {
    NSNumber *wifiSendNumber = [self getDataCounters][0];
    float wifiS = [wifiSendNumber floatValue];
    self.preWifi_S = wifiS;
    
    NSNumber *wifiReceived = [self getDataCounters][1];
    float wifiR = [wifiReceived floatValue];
    self.preWifi_R = wifiR;
    
    NSNumber *wwanSendNumber = [self getDataCounters][2];
    float wwanS = [wwanSendNumber floatValue];
    self.preWWAN_S = wwanS;
    
    NSNumber *wwanReceived = [self getDataCounters][3];
    float wwanR = [wwanReceived floatValue];
    self.preWWAN_R = wwanR;
}

// 上行、下行流量
- (NSArray *)getDataCounters
{
    BOOL success;
    struct ifaddrs *addrs;
    struct ifaddrs *cursor;
    struct if_data *networkStatisc;
    long WiFiSent = 0;
    long WiFiReceived = 0;
    long WWANSent = 0;
    long WWANReceived = 0;
    NSString *name=[[NSString alloc]init];
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            //NSLog(@"ifa_name %s == %@\n", cursor->ifa_name,name);
            // names of interfaces: en0 is WiFi ,pdp_ip0 is WWAN
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (struct if_data *) cursor->ifa_data;
                    WiFiSent += networkStatisc -> ifi_obytes;
                    WiFiReceived += networkStatisc -> ifi_ibytes;
//                    NSLog(@"WiFiSent %ld ==%d",WiFiSent,networkStatisc->ifi_obytes);
//                    NSLog(@"WiFiReceived %ld ==%d",WiFiReceived,networkStatisc->ifi_ibytes);
                }
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (struct if_data *) cursor -> ifa_data;
                    WWANSent += networkStatisc -> ifi_obytes;
                    WWANReceived += networkStatisc -> ifi_ibytes;
//                    NSLog(@"WWANSent %ld ==%d",WWANSent,networkStatisc->ifi_obytes);
//                    NSLog(@"WWANReceived %ld ==%d",WWANReceived,networkStatisc->ifi_ibytes);
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:WiFiSent/1024.f], [NSNumber numberWithInt:WiFiReceived/1024.f],[NSNumber numberWithInt:WWANSent/1024.f],[NSNumber numberWithInt:WWANReceived/1024.f], nil];
}

/**
 内存警告调用方法
 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
