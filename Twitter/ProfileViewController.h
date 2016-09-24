//
//  ProfileViewController.h
//  Twitter
//
//  Created by Nikhil S on 9/21/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (strong, nonatomic) NSString *user;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
