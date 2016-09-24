//
//  ProfileViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/21/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "ProfileViewController.h"
#import "ComposeViewController.h"
#import "TwitterClient.h"
#import "UIImageView+AFNetworking.h"
#import "ProfileCell.h"
#import "ProfTweetCell.h"

@interface ProfileViewController() <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSDictionary *profile;
@property (strong, nonatomic) NSArray *tweets;
@end

@implementation ProfileViewController
- (void)viewDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;
    self.refreshControl = [[UIRefreshControl alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    NSLog(@"view controllers %lu", self.navigationController.viewControllers.count);
    [self loadProfile];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadTweets];
}
- (void)refreshData {
    [self loadProfile];
    [self loadTweets];
}
- (void)loadProfile {
    [TwitterClient loadProfile:self.user withCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            NSLog(@"error loading profile %@", error);
            self.profile = @{};
            return;
        }
        [self handleProfile:response];
    }];
}
- (void)handleProfile:(NSDictionary *)response {
    self.profile = response;
    self.navigationItem.title = self.profile[@"name"];
    [self.tableView reloadData];
    //NSLog(@"profile %@", self.profile);
}

- (void)handleResponse:(NSArray *)response {
    self.tweets = response;
    [self.tableView reloadData];
}
- (void)loadTweets {
    [TwitterClient loadTimeline:self.user withCallback:^(NSArray *response, NSError *error) {
        [self.refreshControl endRefreshing];
        if (error) {
            NSLog(@"error loading tweets %@", error.localizedDescription);
            self.tweets = @[];
            return;
        }
        [self handleResponse:response];
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ProfileCell *pcell = (ProfileCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
        if (self.profile[@"profile_banner_url"] && !(self.profile[@"profile_banner_url"] == [NSNull null])) {
            [pcell.profileBackgroundImage setImageWithURL:[NSURL URLWithString:self.profile[@"profile_banner_url"]]];
        } else if (self.profile[@"profile_background_image_url_https"] && !(self.profile[@"profile_background_image_url_https"] == [NSNull null])) {
            [pcell.profileBackgroundImage setImageWithURL:[NSURL URLWithString:self.profile[@"profile_background_image_url_https"]]];
        } else if (self.profile[@"profile_background_color"]) {
            unsigned backgroundColor = 0;
            NSScanner *scanner = [NSScanner scannerWithString:self.profile[@"profile_background_color"]];
            [scanner scanHexInt:&backgroundColor];
            pcell.profileBackgroundImage.backgroundColor = [UIColor colorWithRed:((backgroundColor & 0xFF0000) >> 16)/255.0 green:((backgroundColor & 0xFF00) >> 8)/255.0 blue:(backgroundColor & 0xFF)/255.0 alpha:1.0];
        }
        if (self.profile[@"profile_image_url_https"] && !(self.profile[@"profile_image_url_https"] == [NSNull null])) {
            [pcell.profileImage setImageWithURL:[NSURL URLWithString:self.profile[@"profile_image_url_https"]]];
        }
        pcell.userNameLabel.text = self.profile[@"name"];
        pcell.userIdLabel.text = [NSString stringWithFormat:@"@%@", self.profile[@"screen_name"]];
        NSLog(@"sta count %@", self.profile[@"statuses_count"]);
        pcell.tweetsLabel.text = [TwitterClient getReadableNumber:(NSNumber *)self.profile[@"statuses_count"]];
        pcell.followingCount.text = [TwitterClient getReadableNumber:(NSNumber *)self.profile[@"friends_count"]];
        pcell.followersCount.text = [TwitterClient getReadableNumber:(NSNumber *)self.profile[@"followers_count"]];
        return pcell;
    }
    NSInteger row = indexPath.row - 1;
    ProfTweetCell *cell = (ProfTweetCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfTweetCell"];
    NSDictionary *tweetUser = self.tweets[row][@"user"];
    NSDictionary *tweet = self.tweets[row];
    NSNumber *favoriteCount = tweet[@"favorite_count"];
    if ([tweet valueForKey:@"retweeted_status"] != nil) {
        tweetUser = tweet[@"retweeted_status"][@"user"];
        favoriteCount = tweet[@"retweeted_status"][@"favorite_count"];
    }
    cell.userNameLabel.text = tweetUser[@"name"];
    NSString *userId = [@"@" stringByAppendingString:tweetUser[@"screen_name"]];
    NSAttributedString *userIdUnderlined = [[NSAttributedString alloc] initWithString:userId attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
    cell.userIdLabel.attributedText = userIdUnderlined;
    cell.tweetLabel.text = self.tweets[row][@"text"];
    cell.tweetTimeLabel.text = [TwitterClient getRelativeDate:self.tweets[row][@"created_at"]];
    [cell.profilePic setImageWithURL:[NSURL URLWithString:tweetUser[@"profile_image_url_https"]]];
    if (!cell.replyIcon.gestureRecognizers) {
        UITapGestureRecognizer *replyTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replyTap:)];
        replyTap.numberOfTapsRequired = 1;
        cell.replyIcon.userInteractionEnabled = YES;
        [cell.replyIcon addGestureRecognizer:replyTap];
    }
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
    cell.likeCountLabel.text = [TwitterClient getReadableNumber:favoriteCount];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"ShowProfile"]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSString *user = self.tweets[indexPath.row - 1][@"user"][@"screen_name"];
        if ([self.tweets[indexPath.row - 1] valueForKey:@"retweeted_status"] != nil) {
            user = self.tweets[indexPath.row - 1][@"retweeted_status"][@"user"][@"screen_name"];
        }
        return ![self.user isEqualToString:user];
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowProfile"]) {
        ProfileViewController *tweetProf = (ProfileViewController *)segue.destinationViewController;
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        tweetProf.user = self.tweets[indexPath.row - 1][@"user"][@"screen_name"];
        if ([self.tweets[indexPath.row - 1] valueForKey:@"retweeted_status"] != nil) {
            tweetProf.user = self.tweets[indexPath.row - 1][@"retweeted_status"][@"user"][@"screen_name"];
        }
    }
}

- (void)replyTap:(UITapGestureRecognizer *)gesture {
    ProfTweetCell *cell = (ProfTweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *tweet = self.tweets[indexPath.row];
    NSString *tweetId = tweet[@"id_str"];
    if ([tweet valueForKey:@"retweeted_status"] != nil) {
        tweetId = tweet[@"retweeted_status"][@"id_str"];
    }
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ComposeViewController *compose = (ComposeViewController*)[mainStory instantiateViewControllerWithIdentifier:@"ComposeViewController"];
    compose.replyTweet = tweetId;
    [self.navigationController pushViewController:compose animated:YES];
}

- (void)retweetTap:(UITapGestureRecognizer *)gesture {
    ProfTweetCell *cell = (ProfTweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger row = indexPath.row - 1;
    NSDictionary *tweet = self.tweets[row];
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
    ProfTweetCell *cell = (ProfTweetCell *)gesture.view.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger row = indexPath.row - 1;
    NSNumber *favoriteCount = self.tweets[row][@"favorite_count"];
    if ([self.tweets[row] valueForKey:@"retweeted_status"] != nil) {
        favoriteCount = self.tweets[row][@"retweeted_status"][@"favorite_count"];
    }
    [TwitterClient doLike:self.tweets[row][@"id_str"] withCallback:^(NSDictionary *response, NSError *error) {
        if (!error) {
            cell.likeIcon.image = [UIImage imageNamed:@"like-on"];
            cell.likeCountLabel.text = [TwitterClient getReadableNumber:[NSNumber numberWithLong:favoriteCount.integerValue+1]];
        }
        //NSLog(@"response %@", response);
    }];
}


@end
