//
//  HamburgerViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "HamburgerViewController.h"
#import "TweetsViewController.h"
#import "ProfileViewController.h"

@interface HamburgerViewController () <MenuSelectDelegate, MenuDelegate>
@property (weak, nonatomic) MenuViewController *menuController;
@property (weak, nonatomic) TweetsViewController *tweetsController;
@property (weak, nonatomic) UINavigationController *tweetsNavController;
@property (weak, nonatomic) ProfileViewController *profileController;
@property (weak, nonatomic) UINavigationController *profileNavController;

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuCenterX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewCenterX;

@end

@implementation HamburgerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.menuController = (MenuViewController*)[mainStory instantiateViewControllerWithIdentifier:@"MenuViewController"];
    self.tweetsNavController = (UINavigationController *)[mainStory instantiateViewControllerWithIdentifier:@"TweetsNavViewController"];
    self.tweetsController = (TweetsViewController*)self.tweetsNavController.visibleViewController;
    self.profileNavController = (UINavigationController *)[mainStory instantiateViewControllerWithIdentifier:@"ProfileNavViewController"];
    self.profileController = (ProfileViewController*)self.profileNavController.visibleViewController;
    self.menuController.menuOwner = self;
    self.menuController.delegate = self;
    self.tweetsController.hmbController = self;
    [self addChildViewController:self.menuController];
    [self addChildViewController:self.tweetsNavController];
    [self addChildViewController:self.profileNavController];
    self.tweetsNavController.view.frame = self.contentView.bounds;
    self.profileNavController.view.frame = self.contentView.bounds;
    self.menuController.view.frame = self.menuView.bounds;
    [self.menuView addSubview:self.menuController.view];
    [self.contentView addSubview:self.tweetsNavController.view];
    [self.tweetsNavController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)closeMenu {
    [UIView animateWithDuration:0.2 animations:^{
        self.contentViewCenterX.constant = 0;
        self.menuCenterX.constant = -100;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.menuController willMoveToParentViewController:nil];
        [self.tweetsNavController didMoveToParentViewController:self];
    }];
}

- (void)openMenu {
    [UIView animateWithDuration:0.2 animations:^{
        self.contentViewCenterX.constant = 200;
        self.menuCenterX.constant = 100;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.tweetsNavController willMoveToParentViewController:nil];
        [self.menuController didMoveToParentViewController:self];
    }];
}

- (IBAction)onPan:(UIPanGestureRecognizer *)sender {
    CGPoint velocity = [sender velocityInView:self.view];
    CGPoint translate = [sender translationInView:self.view];
    if (sender.state == UIGestureRecognizerStateChanged) {
        if (fabs(translate.x) < 200) {
            self.contentViewCenterX.constant = translate.x;
            self.menuCenterX.constant = translate.x - 100;
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if(fabs(translate.x) > 20)  {
            if (velocity.x < 0) {
                [self closeMenu];
            } else {
                [self openMenu];
            }
        } else {
            if (self.contentViewCenterX.constant > 20) {
                [self openMenu];
            } else {
                [self closeMenu];
            }
        }
    }
}

- (void)showProfile:(NSString *)user {
    [self.tweetsNavController willMoveToParentViewController:nil];
    [self.tweetsNavController.view removeFromSuperview];
    self.profileNavController.view.frame = self.contentView.bounds;
    self.profileController.user = user;
    [self.contentView addSubview:self.profileNavController.view];
    [self.profileNavController didMoveToParentViewController:self];
}

- (void)menuItemSelected:(NSUInteger)item {
    if (item == 0) {
        if (self.profileNavController.view.superview != self.contentView) {
            NSLog(@"show profile");
            [self.tweetsNavController willMoveToParentViewController:nil];
            [self.tweetsNavController.view removeFromSuperview];
            self.profileNavController.view.frame = self.contentView.bounds;
            //self.profileController.user = @"elonmusk";
            [self.contentView addSubview:self.profileNavController.view];
            [self.profileNavController didMoveToParentViewController:self];
        }
    } else if (self.tweetsNavController.view.superview != self.contentView) {
        NSLog(@"show tweets");
        [self.profileNavController willMoveToParentViewController:nil];
        [self.profileNavController.view removeFromSuperview];
        self.tweetsNavController.view.frame = self.contentView.bounds;
        [self.contentView addSubview:self.tweetsNavController.view];
        [self.tweetsNavController didMoveToParentViewController:self];
    }
    if ([self.menuSelectDelegate respondsToSelector:@selector(menuItemSelected:)]) {
        [self.menuSelectDelegate menuItemSelected:item];
    }
}

@end
