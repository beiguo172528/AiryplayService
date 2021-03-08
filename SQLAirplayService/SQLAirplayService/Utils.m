//
//  Utils.m
//  SQLAirplayService
//
//  Created by DOFAR on 2021/3/8.
//

#import "Utils.h"
#include <dns_sd.h>
#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include<stdlib.h>

@interface Utils(){
    BOOL _isNext;
}
@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *hostName;

@property(nonatomic, assign) DNSServiceRef airplayService;
@property(nonatomic, assign) DNSRecordRef recordAirplayRef;

@property(nonatomic, assign) DNSServiceRef raopService;
@property(nonatomic, assign) DNSRecordRef recordRaopRef;
@end

@implementation Utils

- (void)registerServiceName:(NSString*)name withIP:(NSString*)ip{
    NSLog(@"name:%@",name);
    NSLog(@"ip:%@",ip);
    NSDictionary *dic = @{@"name":name,@"ip":ip};
    if(self->_isNext){
        [self performSelector:@selector(registerServiceDic:) withObject:dic afterDelay:5];
        return;
    }
    self->_isNext = true;
    [self registerServiceDic:dic];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5), dispatch_get_main_queue(), ^{
        self->_isNext = false;
    });
}

- (void)registerServiceDic:(NSDictionary*)dic{
    NSString *name = dic[@"name"];
    NSString *ip = dic[@"ip"];
    if(!ip || [ip isEqualToString:@""]){
        return;
    }
    if(!self.deviceID || [self.deviceID isEqualToString:@""]){
        self.deviceID = @"6c:5a:b5:63:70:01";
    }
    else{
        NSString *lastString = [self.deviceID substringFromIndex:self.deviceID.length-1];
        self.deviceID = [self.deviceID substringToIndex:self.deviceID.length-1];
        int num = lastString.intValue;
        if(num >= 9){
            num = 0;
        }
        else{
            num += 1;
        }
        self.deviceID = [NSString stringWithFormat:@"%@%d",self.deviceID,num];
    }
    if(!self.hostName || [self.hostName isEqualToString:@""]){
        self.hostName = @"dair.local";
    }
    else{
        NSArray *arr = [self.hostName componentsSeparatedByString:@"."];
        NSString *str = arr[0];
        NSString *lastString = [str substringFromIndex:str.length-1];
        int num = lastString.intValue;
        num += 1;
        NSString *str1 = [str substringToIndex:str.length-1];
        self.hostName = [NSString stringWithFormat:@"%@%d.%@",str1,num,arr[1]];
    }
    NSString *serverName = [name  isEqual: @""] ? @"DoFar" : name;
    [self createAirplayServiceWithDeviceID:self.deviceID withName:serverName withHost:self.hostName withPort:7000 withIP:ip];
    [self createRaopServiceWithName:[NSString stringWithFormat:@"%@@%@",self.deviceID,serverName] withHost:self.hostName withPort:5000 withIP:ip withBaseName:serverName];
}

- (void)removeRecordService{
    if(self.raopService && self.airplayService){
        DNSServiceRemoveRecord(self.airplayService, self.recordAirplayRef, kDNSServiceFlagsDefault);
        DNSServiceRemoveRecord(self.raopService, self.recordRaopRef, kDNSServiceFlagsDefault);
        self.raopService = nil;
        self.airplayService = nil;
        self.recordRaopRef = nil;
        self.recordAirplayRef = nil;
    }
//    else if(self.raopService1 && self.airplayService1){
//        DNSServiceRemoveRecord(self.airplayService1, self.airplayRecordRef1, kDNSServiceFlagsDefault);
//        DNSServiceRemoveRecord(self.raopService1, self.raopRecordRef1, kDNSServiceFlagsDefault);
//        self.raopService1 = nil;
//        self.airplayService1 = nil;
//        self.raopRecordRef1 = nil;
//        self.airplayRecordRef1 = nil;
//    }
    self->_isNext = false;
}

- (void)createAirplayServiceWithDeviceID:(NSString*)deviceID withName:(NSString*)name withHost:(NSString*)host withPort:(int)port withIP:(NSString*)ip{
    DNSServiceRef airplayService = NULL;
    NSDictionary *videoTXTDict = @{
        @"rmodel":@"Android1,0",
        @"srcvers": @"220.68",
        @"pi":@"b08f5a79-db29-4384-b456-a4784d9e6055",
        @"deviceid": deviceID,
        @"vv": @"2",
        @"model": @"AppleTV3,2",
        @"flags": @"0x4",
        @"features": @"0x5A7FFFF7,0x1E",
        @"pk": @"ea4166cf03a89f6d3c7b0c447d3153a6ca777e2843128832a2fb8dadeb37e629",
    };
    TXTRecordRef videoTXTRecord;
    TXTRecordCreate(&videoTXTRecord, 0, NULL);
    for (id key in videoTXTDict.allKeys) {
        TXTRecordSetValue(&videoTXTRecord, [key UTF8String], strlen([videoTXTDict[key] UTF8String]), [videoTXTDict[key] UTF8String]);
    }
    char str[80];
    const char * c1 =[name UTF8String];
    strcpy(str, c1);
    strcat(str, "._airplay._tcp.local");
    DNSServiceRegister(&airplayService, 0, kDNSServiceInterfaceIndexLocalOnly, [name UTF8String], "_airplay._tcp", NULL, str, htons(port), TXTRecordGetLength(&videoTXTRecord), TXTRecordGetBytesPtr(&videoTXTRecord), NULL, NULL);
    NSArray *IPComponents = [ip componentsSeparatedByString:@"."];
    char rawData[5] = {0};
    sprintf(rawData, "%c%c%c%c", (char)[IPComponents[0] integerValue], (char)[IPComponents[1] integerValue], (char)[IPComponents[2] integerValue], (char)[IPComponents[3] integerValue]);
    DNSRecordRef recordRef = NULL;
    DNSServiceAddRecord(airplayService, &recordRef, kDNSServiceFlagsDefault, kDNSServiceType_A, strlen(rawData), rawData, 0);
    self.airplayService = airplayService;
    self.recordAirplayRef = recordRef;
}

- (void)createRaopServiceWithName:(NSString*)name withHost:(NSString*)host withPort:(int)port withIP:(NSString*)ip withBaseName:(NSString*)baseName{
    DNSServiceRef raopService = NULL;
    NSDictionary *raopTXTDict = @{
        @"txtvers":@"1",
        @"ch":@"2",
        @"cn":@"0,1,3",
        @"et":@"0,3,5",
        @"sv":@"false",
        @"da":@"true",
        @"sr":@"44100",
        @"ss":@"16",
        @"vn":@"3",
        @"tp":@"UDP",
        @"md":@"0,1,2",
        @"vs":@"130.14",
        @"sm":@"false",
        @"ek":@"1",
        @"sf":@"0x4",
        @"am":@"Shairport,1",
        @"pk":@"ea4166cf03a89f6d3c7b0c447d3153a6ca777e2843128832a2fb8dadeb37e629"
    };
    TXTRecordRef raopTXTRecord;
    TXTRecordCreate(& raopTXTRecord, 0, NULL);
    for (id key in raopTXTDict.allKeys) {
        TXTRecordSetValue(& raopTXTRecord, [key UTF8String], strlen([raopTXTDict[key] UTF8String]), [raopTXTDict[key] UTF8String]);
    }
    char str[80];
    const char * c1 =[baseName UTF8String];
    strcpy(str, c1);
    strcat(str, "._airplay._tcp.local");
    DNSServiceRegister(&raopService, 0, kDNSServiceInterfaceIndexLocalOnly, [name UTF8String], "_raop._tcp", NULL, str, htons(port), TXTRecordGetLength(&raopTXTRecord), TXTRecordGetBytesPtr(&raopTXTRecord), NULL, NULL);
    NSArray *IPComponents = [ip componentsSeparatedByString:@"."];
    char rawData[5];
    sprintf(rawData, "%c%c%c%c", (char)[IPComponents[0] integerValue], (char)[IPComponents[1] integerValue], (char)[IPComponents[2] integerValue], (char)[IPComponents[3] integerValue]);
    DNSRecordRef recordRef = NULL;
    DNSServiceAddRecord(raopService, &recordRef, kDNSServiceFlagsDefault, kDNSServiceType_A, strlen(rawData), rawData, 0);
    self.raopService = raopService;
    self.recordRaopRef = recordRef;
//    if(!self.raopService){
//        self.raopService = raopService;
//        self.raopRecordRef = recordRef;
//    }
//    else{
//        self.raopService1 = raopService;
//        self.raopRecordRef1 = recordRef;
//    }
}


@end
