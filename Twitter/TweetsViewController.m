//
//  ViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "TweetsViewController.h"
#import "UIImageView+AFNetworking.h"
#import "TwitterClient.h"
#import "TweetCell.h"

@interface TweetsViewController () <UITableViewDelegate, UITableViewDataSource, MenuSelectDelegate>
@property (strong, nonatomic) NSString *errorMsg;
@property (strong, nonatomic) NSArray *tweets;
@property (weak, nonatomic) IBOutlet UITableView *tweetTableView;
@property (weak, nonatomic) IBOutlet UIButton *tweetsLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *tweetsRightButton;

@end

@implementation TweetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tweetTableView.delegate = self;
    self.tweetTableView.dataSource = self;
    self.tweetTableView.rowHeight = UITableViewAutomaticDimension;
    self.tweetTableView.estimatedRowHeight = 120;
    self.hmbController.menuSelectDelegate = self;
    if ([TwitterClient isAuthorized]) {
        [self.tweetsLeftButton setTitle:@"Sign Out" forState:UIControlStateNormal];
        self.navigationItem.title = @"Timeline";
    }
    NSLog(@"loadtweets");
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"loadtweets now");
    if ([TwitterClient isAuthorized]) {
        [self loadTweets];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TweetCell *cell = (TweetCell *)[tableView dequeueReusableCellWithIdentifier:@"TweetCell"];

    NSDictionary *tweetUser = self.tweets[indexPath.row][@"user"];
    NSDictionary *tweet = self.tweets[indexPath.row];
    if ([tweet valueForKey:@"retweeted_status"] != nil) {
        tweetUser = tweet[@"retweeted_status"][@"user"];
    }

    cell.userNameLabel.text = tweetUser[@"name"];
    NSString *userId = [@"@" stringByAppendingString:tweetUser[@"screen_name"]];
    NSAttributedString *userIdUnderlined = [[NSAttributedString alloc] initWithString:userId attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
    cell.userIdLabel.attributedText = userIdUnderlined;
    cell.tweetLabel.text = tweet[@"text"];
    cell.tweetTimeLabel.text = [TwitterClient getRelativeDate:tweet[@"created_at"]];
    NSNumber *retweeted = tweet[@"retweeted"];
    if (retweeted.boolValue) {
        cell.retweetIcon.image = [UIImage imageNamed:@"retweet-on"];
    } else {
        cell.retweetIcon.image = [UIImage imageNamed:@"retweet"];
    }
    if (!cell.retweetIcon.gestureRecognizers) {
        UITapGestureRecognizer *retweetTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retweetTap:)];
        retweetTap.numberOfTapsRequired = 1;
        cell.retweetIcon.userInteractionEnabled = YES;
        [cell.retweetIcon addGestureRecognizer:retweetTap];
    }
    NSNumber *favorited = tweet[@"favorited"];
    if (favorited.boolValue) {
        cell.likeIcon.image = [UIImage imageNamed:@"like-on"];
    } else {
        cell.likeIcon.image = [UIImage imageNamed:@"like"];
    }
    if (!cell.likeIcon.gestureRecognizers) {
        UITapGestureRecognizer *likeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favoriteTap:)];
        likeTap.numberOfTapsRequired = 1;
        cell.likeIcon.userInteractionEnabled = YES;
        [cell.likeIcon addGestureRecognizer:likeTap];
    }
    cell.retweetCountLabel.text = [TwitterClient getReadableNumber:tweet[@"retweet_count"]];
    [cell.profilePic setImageWithURL:[NSURL URLWithString:tweetUser[@"profile_image_url_https"]]];
    if (!cell.profilePic.gestureRecognizers) {
        UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        profileTap.numberOfTapsRequired = 1;
        cell.profilePic.userInteractionEnabled = YES;
        [cell.profilePic addGestureRecognizer:profileTap];
    }
    
    return cell;
}

- (void)handleResponse:(NSArray *)response {
    self.tweets = response;
    if (self.tweets.count == 0 && !self.errorMsg) {
        self.errorMsg = @"No tweets!";
    }
    if (self.errorMsg) {
        UILabel *labelView = [[UILabel alloc] initWithFrame:self.tweetTableView.frame];
        labelView.text = self.errorMsg;
        self.tweetTableView.tableHeaderView = labelView;
    } else {
        self.tweetTableView.tableHeaderView = nil;
    }
    [self.tweetTableView reloadData];
}
- (void)loadTweets {
    self.errorMsg = nil;
    [TwitterClient loadTimeline:nil withCallback:^(NSArray *response, NSError *error) {
        if (error) {
            NSLog(@"error loading tweets %@", error.localizedDescription);
            self.errorMsg = @"Network error";
            self.tweets = @[];
            return;
        }
        [self handleResponse:response];
    }];
}
- (void)loadMentions {
    [TwitterClient loadMentions:^(NSArray *response, NSError *error) {
        if (error) {
            NSLog(@"error loading tweets %@", error.localizedDescription);
            self.errorMsg = @"Network error";
            self.tweets = @[];
            return;
        }
        [self handleResponse:response];
    }];
}
- (void)showProfile:(UITapGestureRecognizer *)gesture {
    TweetCell *cell = (TweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tweetTableView indexPathForCell:cell];
    NSDictionary *tweetUser = self.tweets[indexPath.row][@"user"];
    NSDictionary *tweet = self.tweets[indexPath.row];
    if ([tweet valueForKey:@"retweeted_status"] != nil) {
        tweetUser = tweet[@"retweeted_status"][@"user"];
    }
    [self.hmbController showProfile:tweetUser[@"screen_name"]];
}

- (void)retweetTap:(UITapGestureRecognizer *)gesture {
    TweetCell *cell = (TweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tweetTableView indexPathForCell:cell];
    NSDictionary *tweet = self.tweets[indexPath.row];
    NSNumber *retweetCount = tweet[@"retweet_count"];
    [TwitterClient doRetweet:tweet[@"id_str"] withCallback:^(NSDictionary *response, NSError *error) {
        if (!error) {
            cell.retweetIcon.image = [UIImage imageNamed:@"retweet-on"];
            cell.retweetCountLabel.text = [TwitterClient getReadableNumber:[NSNumber numberWithLong:retweetCount.integerValue+1]];
        }
        //NSLog(@"response %@", response);
    }];
}

- (void)favoriteTap:(UITapGestureRecognizer *)gesture {
    TweetCell *cell = (TweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tweetTableView indexPathForCell:cell];
    [TwitterClient doLike:self.tweets[indexPath.row][@"id_str"] withCallback:^(NSDictionary *response, NSError *error) {
        if (!error) {
            cell.likeIcon.image = [UIImage imageNamed:@"like-on"];
        }
        //NSLog(@"response %@", response);
    }];
}

- (IBAction)onLeftButtonTap:(UIButton *)sender {
    if ([TwitterClient isAuthorized]) {
        [TwitterClient deauthorize];
        [self.tweetsLeftButton setTitle:@"Sign in" forState:UIControlStateNormal];
    } else {
        [TwitterClient authorize];
    }
}
- (IBAction)onRightButtonTap:(UIButton *)sender {
}

- (void)menuItemSelected:(NSUInteger)item {
    switch (item) {
        case 0:
            self.navigationItem.title = @"Profile";
            break;
        case 1:
            self.navigationItem.title = @"Timeline";
            [self loadTweets];
            break;
        case 2:
            self.navigationItem.title = @"Mentions";
            [self loadMentions];
            break;
    }
}

@end
