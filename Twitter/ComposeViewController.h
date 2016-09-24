//
//  ComposeViewController.h
//  Twitter
//
//  Created by Nikhil S on 9/23/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *remaingCount;
@property (weak, nonatomic) IBOutlet UITextView *tweetTextView;

@end
