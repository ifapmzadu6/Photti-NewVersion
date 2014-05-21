//
//  PWURLSession.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWURLSession.h"

#define DEBUG_LOCAL

@interface PWURLSession ()

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionConfiguration *sessionConfigration;
@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation PWURLSession

//static dispatch_queue_t operation_queue() {
//    static dispatch_queue_t operation_queue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        operation_queue = dispatch_queue_create("com.photti.picasawebalbum.queue", DISPATCH_QUEUE_CONCURRENT);
//    });
//    
//    return operation_queue;
//}

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _sessionConfigration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:_sessionConfigration delegate:self delegateQueue:_operationQueue];
    }
    return self;
}

+ (NSURLSession *)sharedSession {
    return [[PWURLSession sharedManager] session];
}

#pragma mark NSURLSessionDelegate
//- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
//#ifdef DEBUG_LOCAL
//    NSLog(@"%s", __func__);
//#endif
//}
//
//- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
//#ifdef DEBUG_LOCAL
//    NSLog(@"%s", __func__);
//#endif
//}
//
//- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
//#ifdef DEBUG_LOCAL
//    NSLog(@"%s", __func__);
//#endif
//}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
#ifdef DEBUG_LOCAL
    NSLog(@"%s", __func__);
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
#ifdef DEBUG_LOCAL
    NSLog(@"%s", __func__);
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
#ifdef DEBUG_LOCAL
    NSLog(@"%s", __func__);
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
#ifdef DEBUG_LOCAL
    NSLog(@"%s", __func__);
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
#ifdef DEBUG_LOCAL
    NSLog(@"%s", __func__);
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
