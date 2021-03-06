# import <React/RCTConvert.h>
# import "RNBatch.h"

@implementation RNBatch

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

- (id)init {
    self = [super init];
    
    return self;
}

RCT_EXPORT_METHOD(start:(BOOL) doNotDisturb)
{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *batchAPIKey = [info objectForKey:@"BatchAPIKey"];
    [BatchMessaging setDoNotDisturb:doNotDisturb];
    [Batch startWithAPIKey:batchAPIKey];
}

RCT_EXPORT_METHOD(optIn)
{
    [Batch optIn];
}

RCT_EXPORT_METHOD(optOut)
{
    [Batch optOut];
}

RCT_EXPORT_METHOD(optOutAndWipeData)
{
    [Batch optOutAndWipeData];
}

// Push Module

RCT_EXPORT_METHOD(push_registerForRemoteNotifications)
{
    [BatchPush registerForRemoteNotifications];
}

RCT_EXPORT_METHOD(push_clearBadge)
{
    [BatchPush clearBadge];
}

RCT_EXPORT_METHOD(push_dismissNotifications)
{
    [BatchPush dismissNotifications];
}

RCT_EXPORT_METHOD(push_getLastKnownPushToken:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* lastKnownPushToken = [BatchPush lastKnownPushToken];
    resolve(lastKnownPushToken);
}

// User module

RCT_EXPORT_METHOD(userData_getInstallationId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* installationId = [BatchUser installationID];
    resolve(installationId);
}

RCT_EXPORT_METHOD(userData_save:(NSArray*)actions)
{
    BatchUserDataEditor *editor = [BatchUser editor];
    for (NSDictionary* action in actions) {
        NSString* type = action[@"type"];
        
        // Set double, long, NSString, bool class values
        if([type isEqualToString:@"setAttribute"]) {
            [editor setAttribute:action[@"value"] forKey:action[@"key"]];
        }
        
        // Handle dates
        // @TODO: prevent date parsing from erroring
        else if([type isEqualToString:@"setDateAttribute"]) {
            double timestamp = [action[@"value"] doubleValue];
            NSTimeInterval unixTimeStamp = timestamp / 1000.0;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTimeStamp];
            [editor setAttribute:date forKey:action[@"key"]];
        }
        
        else if([type isEqualToString:@"removeAttribute"]) {
            [editor removeAttributeForKey:action[@"key"]];
        }
        
        else if([type isEqualToString:@"clearAttributes"]) {
            [editor clearAttributes];
        }
        
        else if([type isEqualToString:@"setIdentifier"]) {
            [editor setIdentifier:action[@"value"]];
        }
        
        else if([type isEqualToString:@"setLanguage"]) {
            [editor setLanguage:action[@"value"]];
        }
        
        else if([type isEqualToString:@"setRegion"]) {
            [editor setRegion:action[@"value"]];
        }
        
        else if([type isEqualToString:@"addTag"]) {
            [editor addTag:action[@"tag"] inCollection:action[@"collection"]];
        }
        
        else if([type isEqualToString:@"removeTag"]) {
            [editor removeTag:action[@"tag"] fromCollection:action[@"collection"]];
        }
        
        else if([type isEqualToString:@"clearTagCollection"]) {
            [editor clearTagCollection:action[@"collection"]];
        }
        
        else if([type isEqualToString:@"clearTags"]) {
            [editor clearTags];
        }
    }
    [editor save];
}

// Event tracking

RCT_EXPORT_METHOD(userData_trackEvent:(NSString*)name label:(NSString*)label data:(NSDictionary*)serializedEventData)
{
    BatchEventData *batchEventData = nil;
    
    if ([serializedEventData isKindOfClass:[NSDictionary class]])
    {
        batchEventData = [BatchEventData new];
        
        if (![serializedEventData isKindOfClass:[NSDictionary class]])
        {
            NSLog(@"RNBatch: Error while tracking event data: event data should be an object or null");
            return;
        }
        
        NSArray<NSString*>* tags = serializedEventData[@"tags"];
        NSDictionary<NSString*, NSDictionary*>* attributes = serializedEventData[@"attributes"];
        
        if (![tags isKindOfClass:[NSArray class]])
        {
            NSLog(@"RNBatch: Error while tracking event data: event data.tags should be an array");
            return;
        }
        if (![attributes isKindOfClass:[NSDictionary class]])
        {
            NSLog(@"RNBatch: Error while tracking event data: event data.attributes should be a dictionnary");
            return;
        }
        
        for (NSString *tag in tags)
        {
            if (![tag isKindOfClass:[NSString class]])
            {
                NSLog(@"RNBatch: Error while tracking event data: event data.tag childrens should all be strings");
                return;
            }
            [batchEventData addTag:tag];
        }
        
        for (NSString *key in attributes.allKeys)
        {
            NSDictionary *typedAttribute = attributes[key];
            if (![typedAttribute isKindOfClass:[NSDictionary class]])
            {
                NSLog(@"RNBatch: Error while tracking event data: event data.attributes childrens should all be String/Dictionary tuples");
                return;
            }
            
            NSString *type = typedAttribute[@"type"];
            NSObject *value = typedAttribute[@"value"];
            
            if ([@"string" isEqualToString:type]) {
                if (![value isKindOfClass:[NSString class]])
                {
                    NSLog(@"RNBatch: Error while tracking event data: event data.attributes: expected string value, got something else");
                    return;
                }
                [batchEventData putString:(NSString*)value forKey:key];
            } else if ([@"boolean" isEqualToString:type]) {
                if (![value isKindOfClass:[NSNumber class]])
                {
                    NSLog(@"RNBatch: Error while tracking event data: event data.attributes: expected number (boolean) value, got something else");
                    return;
                }
                [batchEventData putBool:[(NSNumber*)value boolValue] forKey:key];
            } else if ([@"integer" isEqualToString:type]) {
                if (![value isKindOfClass:[NSNumber class]])
                {
                    NSLog(@"RNBatch: Error while tracking event data: event data.attributes: expected number (integer) value, got something else");
                    return;
                }
                [batchEventData putInteger:[(NSNumber*)value integerValue] forKey:key];
            } else if ([@"float" isEqualToString:type]) {
                if (![value isKindOfClass:[NSNumber class]])
                {
                    NSLog(@"RNBatch: Error while tracking event data: event data.attributes: expected number (float) value, got something else");
                    return;
                }
                [batchEventData putDouble:[(NSNumber*)value doubleValue] forKey:key];
            } else {
                NSLog(@"RNBatch: Error while tracking event data: Unknown event data.attributes type");
                return;
            }
        }
    }
    
    [BatchUser trackEvent:name withLabel:label associatedData:batchEventData];
}

RCT_EXPORT_METHOD(userData_trackTransaction:(double)amount data:(NSDictionary*)rawData)
{
    if (rawData && ![rawData isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"RNBatch: trackTransaction data should be an dictionary or nil");
        return;
    }
    
    [BatchUser trackTransactionWithAmount:amount data:rawData];
}

RCT_EXPORT_METHOD(userData_trackLocation:(NSDictionary*)serializedLocation)
{
    if (![serializedLocation isKindOfClass:[NSDictionary class]] || [serializedLocation count]==0)
    {
        NSLog(@"RNBatch: Empty or null parameters for trackLocation");
        return;
    }
    
    NSNumber *latitude = serializedLocation[@"latitude"];
    NSNumber *longitude = serializedLocation[@"longitude"];
    NSNumber *date = serializedLocation[@"date"]; // MS
    NSNumber *precision = serializedLocation[@"precision"];
    
    if (![latitude isKindOfClass:[NSNumber class]])
    {
        NSLog(@"RNBatch: latitude should be a string");
        return;
    }
    
    if (![longitude isKindOfClass:[NSNumber class]])
    {
        NSLog(@"RNBatch: longitude should be a string");
        return;
    }
    
    NSTimeInterval ts = 0;
    
    if (date)
    {
        if ([date isKindOfClass:[NSNumber class]]) {
            ts = [date doubleValue] / 1000.0;
        } else {
            NSLog(@"RNBatch: date should be an object or undefined");
            return;
        }
    }
    
    NSDate *parsedDate = ts != 0 ? [NSDate dateWithTimeIntervalSince1970:ts] : [NSDate date];
    
    NSInteger parsedPrecision = 0;
    if (precision)
    {
        if ([precision isKindOfClass:[NSNumber class]]) {
            parsedPrecision = [precision integerValue];
        } else {
            NSLog(@"RNBatch: precision should be an object or undefined");
            return;
        }
    }
    
    [BatchUser trackLocation:[[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue])
                                                           altitude:0
                                                 horizontalAccuracy:parsedPrecision
                                                   verticalAccuracy:-1
                                                             course:0
                                                              speed:0
                                                          timestamp:parsedDate]];
}

// Inbox module

RCT_EXPORT_METHOD(inbox_fetchNotifications:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BatchInboxFetcher* fetcher = [BatchInbox fetcher];
    [fetcher fetchNewNotifications:^(NSError * _Nullable error, NSArray<BatchInboxNotificationContent *> * _Nullable notifications, BOOL foundNewNotifications, BOOL endReached) {
        
        if (error) {
            reject(@"Inbox", @"Failed to fetch new notifications", error);
        }
        
        
    }];
}

// Messaging module

RCT_EXPORT_METHOD(messaging_setNotDisturbed:(BOOL) active)
{
    [BatchMessaging setDoNotDisturb:active];
}

RCT_EXPORT_METHOD(messaging_showPendingMessage) {
    [BatchMessaging showPendingMessage];
}

@end
