//
//  Utils.h
//  SQLAirplayService
//
//  Created by DOFAR on 2021/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject
- (void)registerServiceName:(NSString*)name withIP:(NSString*)ip;
- (void)removeRecordService;
@end

NS_ASSUME_NONNULL_END
