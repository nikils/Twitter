//
//  HamburgerViewController.h
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuDelegate.h"
#import "MenuViewController.h"

@interface HamburgerViewController : UIViewController
@property (weak, nonatomic) id <MenuSelectDelegate> menuSelectDelegate;
- (void)showProfile:(NSString *)user;
- (void)closeMenu;
@end
