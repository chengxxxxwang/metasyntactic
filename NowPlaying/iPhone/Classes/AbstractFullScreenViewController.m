//
//  AbstractFullScreenViewController.m
//  NowPlaying
//
//  Created by Cyrus Najmabadi on 3/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AbstractFullScreenViewController.h"

#import "AppDelegate.h"
#import "NotificationCenter.h"

@implementation AbstractFullScreenViewController

- (BOOL) hidesBottomBarWhenPushed {
    return YES;
}


- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    [[AppDelegate notificationCenter] disableNotifications];
}


- (void) viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];
    [[AppDelegate notificationCenter] enableNotifications];
}

@end
