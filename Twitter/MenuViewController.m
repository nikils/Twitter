//
//  MenuViewController.m
//  Twitter
//
//  Created by Nikhil S on 9/19/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuCell.h"
#import "TwitterClient.h"

@interface MenuViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuCell *cell = (MenuCell *)[tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    switch (indexPath.row) {
        case 0:
            cell.menuLabelView.text = @"Profile";
            break;
     
        case 1:
            cell.menuLabelView.text = @"Timeline";
            break;
            
        case 2:
            cell.menuLabelView.text = @"Mentions";
            break;
        case 3:
            if ([TwitterClient isAuthorized]) {
                cell.menuLabelView.text = @"Sign Out";
            } else {
                cell.menuLabelView.text = @"Sign In";
            }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([self.menuOwner respondsToSelector:@selector(closeMenu)]) {
        [self.menuOwner closeMenu];
    }
    if ([self.delegate respondsToSelector:@selector(menuItemSelected:)]) {
        [self.delegate menuItemSelected:indexPath.row];
    }
    if (indexPath.row == 3) {
        if ([TwitterClient isAuthorized]) {
            [TwitterClient deauthorize];
            MenuCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.menuLabelView.text = @"Sign In";
        } else {
            [TwitterClient authorize];
        }
    }
}


@end
