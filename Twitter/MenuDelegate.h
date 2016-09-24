//
//  MenuDelegate.h
//  Twitter
//
//  Created by Nikhil S on 9/21/16.
//  Copyright © 2016 Nikhil S. All rights reserved.
//

#ifndef MenuDelegate_h
#define MenuDelegate_h

@protocol MenuDelegate<NSObject>
- (void)openMenu;
- (void)closeMenu;
@end

@protocol MenuSelectDelegate<NSObject>
@optional
- (void)menuItemSelected:(NSUInteger)item;
@end

#endif /* MenuDelegate_h */
