#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(WidgetKitModule, NSObject)

RCT_EXTERN_METHOD(setWidgetData:(NSString *)jsonData)
RCT_EXTERN_METHOD(reloadAllTimelines)
RCT_EXTERN_METHOD(reloadTimeline:(NSString *)kind)
RCT_EXTERN_METHOD(getCurrentConfigurations:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
