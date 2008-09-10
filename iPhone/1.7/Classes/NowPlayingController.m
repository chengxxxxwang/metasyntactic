// Copyright (C) 2008 Cyrus Najmabadi
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option) any
// later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program; if not, write to the Free Software Foundation, Inc., 51
// Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import "NowPlayingController.h"

#import "Application.h"
#import "ApplicationTabBarController.h"
#import "DataProvider.h"
#import "DateUtilities.h"
#import "GlobalActivityIndicator.h"
#import "NorthAmericaDataProvider.h"
#import "NowPlayingAppDelegate.h"
#import "NowPlayingModel.h"
#import "RatingsCache.h"
#import "ThreadingUtilities.h"
#import "UpcomingCache.h"
#import "Utilities.h"

@implementation NowPlayingController

@synthesize appDelegate;
@synthesize dataProviderLock;
@synthesize ratingsLookupLock;
@synthesize upcomingMoviesLookupLock;

- (void) dealloc {
    self.appDelegate = nil;
    self.dataProviderLock = nil;
    self.ratingsLookupLock = nil;
    self.upcomingMoviesLookupLock = nil;

    [super dealloc];
}


- (NowPlayingModel*) model {
    return appDelegate.model;
}


- (BOOL) tooSoon:(NSDate*) lastDate {
    if (lastDate == nil) {
        return NO;
    }

    NSDate* now = [NSDate date];

    if (![DateUtilities isSameDay:now date:lastDate]) {
        // different days. we definitely need to refresh
        return NO;
    }

    NSDateComponents* lastDateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:lastDate];
    NSDateComponents* nowDateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:now];

    // same day, check if they're at least 8 hours apart.
    if (nowDateComponents.hour >= (lastDateComponents.hour + 8)) {
        return NO;
    }

    // it's been less than 8 hours. it's too soon to refresh
    return YES;
}


- (void) spawnDataProviderLookupThread {
    if ([Utilities isNilOrEmpty:self.model.userLocation]) {
        return;
    }

    if ([self tooSoon:[self.model.currentDataProvider lastLookupDate]]) {
        return;
    }

    [ThreadingUtilities performSelector:@selector(lookup)
                               onTarget:self.model.currentDataProvider
               inBackgroundWithArgument:nil
                                   gate:dataProviderLock
                                visible:YES];
}


- (void) spawnRatingsLookupThread {
    NSDate* lastLookupDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[Application ratingsFile:self.model.currentRatingsProvider]
                                                                               error:NULL] objectForKey:NSFileModificationDate];
    if ([self tooSoon:lastLookupDate]) {
        return;
    }

    [ThreadingUtilities performSelector:@selector(ratingsLookupBackgroundThreadEntryPoint)
                               onTarget:self
               inBackgroundWithArgument:nil
                                   gate:ratingsLookupLock
                                visible:YES];
}


- (void) spawnUpcomingMoviesLookupThread {
    NSDate* lastLookupDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[Application upcomingMoviesIndexFile]
                                                                               error:NULL] objectForKey:NSFileModificationDate];

    if ([self tooSoon:lastLookupDate]) {
        return;
    }

    [ThreadingUtilities performSelector:@selector(updateMoviesList)
                               onTarget:self.model.upcomingCache
               inBackgroundWithArgument:nil
                                   gate:upcomingMoviesLookupLock
                                visible:YES];
}


- (void) spawnBackgroundThreads {
    [self spawnRatingsLookupThread];
    [self spawnDataProviderLookupThread];
    [self spawnUpcomingMoviesLookupThread];
}


- (id) initWithAppDelegate:(NowPlayingAppDelegate*) appDelegate_ {
    if (self = [super init]) {
        self.appDelegate = appDelegate_;
        self.dataProviderLock = [[[NSLock alloc] init] autorelease];
        self.ratingsLookupLock = [[[NSLock alloc] init] autorelease];
        self.upcomingMoviesLookupLock = [[[NSLock alloc] init] autorelease];

        [self spawnBackgroundThreads];
    }

    return self;
}


+ (NowPlayingController*) controllerWithAppDelegate:(NowPlayingAppDelegate*) appDelegate {
    return [[[NowPlayingController alloc] initWithAppDelegate:appDelegate] autorelease];
}


- (NSDictionary*) ratingsLookup {
    return [self.model.ratingsCache update];
}


- (void) ratingsLookupBackgroundThreadEntryPoint {
    NSDictionary* ratings = [self ratingsLookup];
    [self performSelectorOnMainThread:@selector(setRatings:) withObject:ratings waitUntilDone:NO];

}


- (void) setRatings:(NSDictionary*) ratings {
    if (ratings.count > 0) {
        [self.model onRatingsUpdated];
    }
}


- (void) setSearchDate:(NSDate*) searchDate {
    if ([searchDate isEqual:self.model.searchDate]) {
        return;
    }

    [self.model setSearchDate:searchDate];
    [self spawnBackgroundThreads];
    [appDelegate.tabBarController popNavigationControllersToRoot];
    [appDelegate.tabBarController refresh];
}


- (void) setUserLocation:(NSString*) userLocation {
    if ([userLocation isEqual:self.model.userLocation]) {
        return;
    }

    [self.model setUserLocation:userLocation];
    [self spawnBackgroundThreads];
    [appDelegate.tabBarController popNavigationControllersToRoot];
    [appDelegate.tabBarController refresh];
}


- (void) setSearchRadius:(NSInteger) radius {
    [self.model setSearchRadius:radius];
    [appDelegate.tabBarController refresh];
}


- (void) setRatingsProviderIndex:(NSInteger) index {
    if (index == self.model.ratingsProviderIndex) {
        return;
    }

    [self.model setRatingsProviderIndex:index];
    [self spawnRatingsLookupThread];
    [appDelegate.tabBarController refresh];
}


- (void) setDataProviderIndex:(NSInteger) index {
    if (index == self.model.dataProviderIndex) {
        return;
    }

    [self.model setDataProviderIndex:index];
    [self spawnDataProviderLookupThread];
    [appDelegate.tabBarController refresh];
}


@end