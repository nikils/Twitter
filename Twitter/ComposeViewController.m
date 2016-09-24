//
//  ComposeViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/23/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "ComposeViewController.h"
#import "TwitterClient.h"
#import "UIImageView+AFNetworking.h"

@interface ComposeViewController() <UITextViewDelegate>

@end
@implementation ComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tweetTextView.delegate = self;
    self.remaingCount.text = [NSString stringWithFormat:@"%lu", 140-self.tweetTextView.text.length];
    [self loadProfile];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tweetTextView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.remaingCount.text = [NSString stringWithFormat:@"%lu", 140-textView.text.length];
    if (textView.text.length >= 140) {
      [self.tweetTextView resignFirstResponder];
    }
}
- (void)loadProfile {
    [TwitterClient loadProfile:nil withCallback:^(NSDictionary *response, NSError *error) {
        if (error) {
            NSLog(@"error loading profile %@", error);
            return;
        }
        [self handleProfile:response];
    }];
}

- (void)handleProfile:(NSDictionary *)profile {
    if (profile[@"profile_image_url_https"] && !(profile[@"profile_image_url_https"] == [NSNull null])) {
        [self.profilePic setImageWithURL:[NSURL URLWithString:profile[@"profile_image_url_https"]]];
    }
    self.userNameLabel.text = profile[@"name"];
    self.userIdLabel.text = [NSString stringWithFormat:@"@%@", profile[@"screen_name"]];

}
- (IBAction)onTweetButtonTap:(UIButton *)sender {
    [self.tweetTextView resignFirstResponder];
    [TwitterClient doTweet:self.tweetTextView.text withCallback:^(NSDictionary *resp, NSError *error) {
        if (!error) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

@end
