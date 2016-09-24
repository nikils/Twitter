//
//  TwitterClient.m
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterClient.h"
#import "BDBOAuth1SessionManager.h"
#import "NSDictionary+BDBOAuth1Manager.h"


@interface TwitterClient ()
+ (void)initNetworkManager;
+ (void)parseTweets:(id)responseObject completion:(void (^)(NSArray *, NSError *))completion;
@end

static NSString * const TWITTER_BASE_URL = @"https://api.twitter.com/";
static NSString * const TWITTER_CONSUMER_KEY = @"DpJLMyK5QNEcw4o2SPRbBXDXo";
static NSString * const TWITTER_SECRET = @"vQyX3A70pYFt3sHfRwaiYmLut8fOEpFVeCrPM5YtxfHkVEtl4E";
static NSString * const TWITTER_AUTHORIZE_URL = @"https://api.twitter.com/oauth/authorize";
static NSString * const TWITTER_REQUEST_TOKEN = @"oauth/request_token";
static NSString * const TWITTER_ACCESS_TOKEN = @"oauth/access_token";


static BDBOAuth1SessionManager *networkManager;

@implementation TwitterClient

+ (void)initNetworkManager {
    NSURL *baseURL = [NSURL URLWithString:TWITTER_BASE_URL];
    networkManager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:baseURL consumerKey:TWITTER_CONSUMER_KEY consumerSecret:TWITTER_SECRET];
}

+ (BOOL)isAuthorized {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    return networkManager.isAuthorized;
}
+ (void)authorize {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSURL *callbackURL = [NSURL URLWithString:@"iostwitter://authorize"];
    
    [networkManager fetchRequestTokenWithPath:TWITTER_REQUEST_TOKEN method:@"POST" callbackURL:callbackURL scope:nil success:^(BDBOAuth1Credential *requestToken) {
        NSString *authURLString = [TWITTER_AUTHORIZE_URL stringByAppendingFormat:@"?oauth_token=%@", requestToken.token];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURLString]];
    } failure:^(NSError *error) {
        NSLog(@"request token failed %@", error.localizedDescription);
    }];
}

+ (void)deauthorize {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }

    [networkManager deauthorize];
}

+ (void)handleAuthorizationCallbackURL:(NSURL *)url success:(void (^)())success {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSLog(@"handle authorization callback %@", url);

    NSDictionary *parameters = [NSDictionary bdb_dictionaryFromQueryString:url.query];
    if (parameters[BDBOAuth1OAuthTokenParameter] && parameters[BDBOAuth1OAuthVerifierParameter]) {
        [networkManager fetchAccessTokenWithPath:TWITTER_ACCESS_TOKEN method:@"POST" requestToken:[BDBOAuth1Credential credentialWithQueryString:url.query] success:^(BDBOAuth1Credential *accessToken) {
            NSLog(@"got access token %@", accessToken);
            success();
        } failure:^(NSError *error) {
            NSLog(@"access token failed: %@", error.localizedDescription);

        }];
    }
}

+ (void)loadTweets:(NSString *)endpoint withCallback:(void (^)(NSArray *, NSError *)) completion {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }

    [networkManager GET:endpoint parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        [TwitterClient parseTweets:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"getting tweets failed %@", error);
        completion(nil, error);
    }];
}

+ (void)parseTweets:(id)responseObject completion:(void (^)(NSArray *, NSError *))completion {
    if (![responseObject isKindOfClass:[NSArray class]]) {
        NSError *error = [NSError errorWithDomain:@"TweetError" code:1000 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];
        return completion(nil, error);
    }
    NSArray *response = responseObject;
    //NSLog(@"Tweet response %@", response);
    completion(response, nil);
}

+ (void)loadTimeline:(NSString *)user withCallback:(void (^)(NSArray *, NSError *)) completion {
    NSString *url = @"1.1/statuses/home_timeline.json?count=20";
    if (user) {
        url = [NSString stringWithFormat:@"1.1/statuses/user_timeline.json?screen_name=%@&count=20", user];
    }
    [TwitterClient loadTweets:url withCallback:completion];
}

+ (void)loadMentions:(void (^)(NSArray *, NSError *)) completion {
    [TwitterClient loadTweets:@"1.1/statuses/mentions_timeline.json?count=20" withCallback:completion];
}

+ (void)loadProfile:(NSString *)user withCallback:(void (^)(NSDictionary *, NSError *)) completion {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSString *url = @"1.1/account/verify_credentials.json";
    if (user) {
        url = [NSString stringWithFormat:@"1.1/users/show.json?screen_name=%@", user];
    }
    
    [networkManager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"TweetError" code:1001 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];
            return completion(nil, error);
        }
        NSDictionary *resp = responseObject;
        completion(resp, nil);
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"getting tweets failed %@", error);
        completion(nil, error);
    }];

}

+ (void)doTweet:(NSString *)tweet forReply:(NSString *)tweetId withCallback:(void (^)(NSDictionary *, NSError *)) completion {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSString *url = [NSString stringWithFormat:@"1.1/statuses/update.json?status=%@", [tweet stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    if (tweetId) {
        url = [NSString stringWithFormat:@"1.1/statuses/update.json?status=%@&in_reply_to_status_id=%@", [tweet stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], [tweetId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    [networkManager POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"TweetError" code:1002 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];
            return completion(nil, error);
        }
        NSDictionary *resp = responseObject;
        completion(resp, nil);
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"tweeting failed %@", error);
        completion(nil, error);
    }];
}

+ (void)doRetweet:(NSString *)tweetId withCallback:(void (^)(NSDictionary *, NSError *)) completion {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSString *url = [NSString stringWithFormat:@"1.1/statuses/retweet/%@.json", [tweetId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [networkManager POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"TweetError" code:1003 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];
            return completion(nil, error);
        }
        NSDictionary *resp = responseObject;
        completion(resp, nil);
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"retweeting failed %@", error);
        completion(nil, error);
    }];
}

+ (void)doLike:(NSString *)tweetId withCallback:(void (^)(NSDictionary *, NSError *)) completion {
    if (!networkManager) {
        [TwitterClient initNetworkManager];
    }
    
    NSString *url = [NSString stringWithFormat:@"1.1/favorites/create.json?id=%@", [tweetId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [networkManager POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"TweetError" code:1004 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unexpected response received from Twitter API.", nil)}];
            return completion(nil, error);
        }
        NSDictionary *resp = responseObject;
        completion(resp, nil);
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"liking failed %@", error);
        completion(nil, error);
    }];
}

+ (NSString *)getRelativeDate:(NSString *)date {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"E MMM d H:m:s XXXX y"];
    NSDate *createdAt = [dateFormat dateFromString:date];
    NSTimeInterval timeSinceDate = [[NSDate date] timeIntervalSinceDate:createdAt];
    if(timeSinceDate < 24.0 * 60.0 * 60.0) {
        NSUInteger hoursSinceDate = (NSUInteger)(timeSinceDate / (60.0 * 60.0));
        NSUInteger minutesSinceDate = (NSUInteger)(timeSinceDate / 60.0);
        switch(hoursSinceDate) {
            case 0:
                switch (minutesSinceDate) {
                    case 0:
                    case 1:
                    case 2:
                        return @"now";
                    default:
                        return [NSString stringWithFormat:@"%lum", minutesSinceDate];
                }
            case 1: return @"1h";
            default:
                return [NSString stringWithFormat:@"%luh", hoursSinceDate];
        }
    } else {
        NSDateFormatter *strDateFormat = [[NSDateFormatter alloc] init];
        strDateFormat.timeStyle = NSDateFormatterNoStyle;
        strDateFormat.dateStyle = NSDateFormatterShortStyle;
        strDateFormat.doesRelativeDateFormatting = YES;
        return [strDateFormat stringFromDate:createdAt];
    }
}

+ (NSString *)getReadableNumber:(NSNumber *)number {
    if (number.integerValue > 1000*1000*1000) {
        return [NSString stringWithFormat:@"%luB", (number.integerValue/(1000*1000*1000))];
    } else if (number.integerValue > 1000*1000) {
        return [NSString stringWithFormat:@"%luM", (number.integerValue/(1000*1000))];
    } else if (number.integerValue > 1000) {
        return [NSString stringWithFormat:@"%luK", (number.integerValue/(1000))];
    } else {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter stringFromNumber:number];
    }
}

@end
