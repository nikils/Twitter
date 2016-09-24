//
//  TwitterClient.h
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterClient : NSObject

+ (BOOL)isAuthorized;
+ (void)authorize;
+ (void)deauthorize;
+ (void)handleAuthorizationCallbackURL:(NSURL *)url success:(void (^)())success;
+ (void)loadTweets:(NSString *)endpoint withCallback:(void (^)(NSArray *, NSError *)) completion;
+ (void)loadTimeline:(NSString *)user withCallback:(void (^)(NSArray *, NSError *)) completion;
+ (void)loadMentions:(void (^)(NSArray *, NSError *)) completion;
+ (void)loadProfile:(NSString *)user withCallback:(void (^)(NSDictionary *, NSError *)) completion;
+ (void)doTweet:(NSString *)tweet withCallback:(void (^)(NSDictionary *, NSError *)) completion;
+ (void)doRetweet:(NSString *)tweetId withCallback:(void (^)(NSDictionary *, NSError *)) completion;
+ (void)doLike:(NSString *)tweetId withCallback:(void (^)(NSDictionary *, NSError *)) completion;
+ (NSString *)getRelativeDate:(NSString *)date;
+ (NSString *)getReadableNumber:(NSNumber *)number;

@end
