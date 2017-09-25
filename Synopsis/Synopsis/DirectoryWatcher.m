//
//  FileWatcher.m
//  Synopsis
//
//  Created by vade on 9/14/17.
//  Copyright © 2017 metavisual. All rights reserved.
//

#import "DirectoryWatcher.h"

@interface DirectoryWatcher (FSEventStreamCallbackSupport)
- (void) coalescedNotificationWithChangedURLArray:(NSArray<NSURL*>*)changedUrls;
@end

#pragma mark -

void mycallback(u
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    @autoreleasepool
    {
        if(clientCallBackInfo != NULL)
        {
            DirectoryWatcher* watcher = (__bridge DirectoryWatcher*)(clientCallBackInfo);

            int i;
            char **paths = eventPaths;
            
            NSMutableArray* changedURLS = [NSMutableArray new];
            
//            for (i = 0; i < numEvents; i++)
//            {
//                NSString* filePath = [[NSString alloc] initWithCString:paths[i] encoding:NSUTF8StringEncoding];
//                NSURL* fileURL = [NSURL fileURLWithPath:filePath];
//                [changedURLS addObject:fileURL];
//            }
            
            [watcher coalescedNotificationWithChangedURLArray:changedURLS];
        }
    }
}

#pragma mark -

@interface DirectoryWatcher ()
{
    FSEventStreamRef eventStream;
}
@property (readwrite, strong) NSURL* directoryURL;
@property (readwrite, copy) FileWatchNoticiationBlock notificationBlock;

@property (readwrite, strong) NSSet* latestDirectorySet;

@end

@implementation DirectoryWatcher

- (instancetype) initWithDirectoryAtURL:(NSURL*)url notificationBlock:(FileWatchNoticiationBlock)notificationBlock
{
    self = [super init];
    if(self)
    {
        eventStream = NULL;
        
        if([url isFileURL])
        {
            NSNumber* isDirValue;
            NSError* error;
            if([url getResourceValue:&isDirValue forKey:NSURLIsDirectoryKey error:&error])
            {
                if([isDirValue boolValue])
                {
                    self.directoryURL = url;
                    
                    self.latestDirectorySet = [self generateHeirarchyForURL:self.directoryURL];
                    
                    self.notificationBlock = notificationBlock;
                    
                    //[self initDispatch];
                    [self initFSEvents];
                }
            }
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

- (void) initFSEvents
{
    if(eventStream)
    {
        FSEventStreamStop(eventStream);
        FSEventStreamRelease(eventStream);
        eventStream = NULL;
    }
    
    NSArray* paths = @[ [self.directoryURL path]];
    
    FSEventStreamContext* context = (FSEventStreamContext*) malloc(sizeof(FSEventStreamContext));
    context->info = (__bridge void*) (self);
    context->release = NULL;
    context->retain = NULL;
    context->version = 0;
    context->copyDescription = NULL;
    
    eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                      mycallback,
                                      context,
                                      (CFArrayRef)CFBridgingRetain(paths),
                                      kFSEventStreamEventIdSinceNow,
                                      1.0,
                                      kFSEventStreamCreateFlagNone | kFSEventStreamCreateFlagIgnoreSelf);
    
    FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    FSEventStreamStart(eventStream);
}

- (void) dealloc
{
    if(eventStream)
    {
        FSEventStreamStop(eventStream);
        FSEventStreamInvalidate(eventStream);
        FSEventStreamRelease(eventStream);
        eventStream = NULL;
    }
}

- (NSSet*) generateHeirarchyForURL:(NSURL*)url;
{
    NSMutableSet* urlSet = [[NSMutableSet alloc] init];
    
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtURL:url
                                                             includingPropertiesForKeys:[NSArray array]
                                                                                options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                           errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                                               return YES;
                                                                           }];

    
    
    for (NSURL* url in enumerator)
    {
        [urlSet addObject:url];
    }
    
    return urlSet;
}



- (void) coalescedNotificationWithChangedURLArray:(NSArray<NSURL*>*)changedUrls
{
    if(self.notificationBlock)
    {
        NSSet* currentDirectorySet = [self generateHeirarchyForURL:self.directoryURL];
        
        NSMutableSet* deltaSet = [[NSMutableSet alloc] init];
        [deltaSet setSet:[self.latestDirectorySet copy]];
        
        [deltaSet intersectSet:currentDirectorySet];
        
        self.latestDirectorySet = currentDirectorySet;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.notificationBlock([deltaSet allObjects]);
        });
    }
}



@end
