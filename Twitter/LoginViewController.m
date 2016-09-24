//
//  LoginViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "LoginViewController.h"
#import "TwitterClient.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onLoginButton:(UIButton *)sender {
    if (![TwitterClient isAuthorized]) {
        [TwitterClient authorize];
    } else {
        NSLog(@"User is authorized");
        [TwitterClient loadTweets:@"1.1/statuses/home_timeline.json?count=20" withCallback:^(NSArray *tweets, NSError *error) {
            if (!error) {
                NSLog(@"Success");
            }
        }];
    }
}

@end
