//
//  ProfileCell.h
//  Twitter
//
//  Created by Nikhil S on 9/22/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileBackgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *tweetsLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingCount;
@property (weak, nonatomic) IBOutlet UILabel *followersCount;

@end
