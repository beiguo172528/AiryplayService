功能:
在app开发中，可能会出现 服务端开启了服务，但是手机这边没有收到信息，这个时候，我们就需要自己注册一个服务。这个服务直接连接到服务端的ip地址，以及自己定义一个服务名称。
本项目中，注册的是投屏服务。如果需要其他服务，可以用相同的思路实现。


步骤：
1. 各种权限
<key>NSLocalNetworkUsageDescription</key>
<string>是否允许使用你的本地网络?以便你的投屏。</string>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>NSBonjourServices</key>
<array>
    <string>_tictactoe._tcp</string>
    <string>_raop._tcp</string>
    <string>_airplay._tcp</string>
</array>

2.注册
服务名称 及 ip地址
- (void)registerServiceName:(NSString*)name withIP:(NSString*)ip

3.取消服务
- (void)removeRecordService;
