//
//  MenuViewController.h
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuDelegate.h"

@interface MenuViewController : UIViewController
@property (weak, nonatomic) id <MenuDelegate> menuOwner;
@property (weak, nonatomic) id <MenuSelectDelegate> delegate;

@end
