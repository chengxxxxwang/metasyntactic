//
//  BoxOfficeController.m
//  BoxOffice
//
//  Created by Cyrus Najmabadi on 4/30/08.
//  Copyright 2008 Metasyntactic. All rights reserved.
//

#import "BoxOfficeController.h"
#import "Movie.h"
#import "Theater.h"
#import "BoxOfficeAppDelegate.h"
#import "XmlParser.h"
#import "XmlDocument.h"
#import "XmlElement.h"
#import "XmlSerializer.h"
#import "Application.h"
#import "Utilities.h"
#import "ExtraMovieInformation.h"
#import "Performance.h"
#import "RottenTomatoesDownloader.h"
#import "MetacriticDownloader.h"

@implementation BoxOfficeController

@synthesize ratingsLookupLock;
@synthesize fullLookupLock;

- (void) dealloc {
    self.ratingsLookupLock = nil;
    self.fullLookupLock = nil;
    [super dealloc];
}

- (BoxOfficeModel*) model {
    return appDelegate.model;
}

- (void) onBackgroundTaskStarted:(NSString*) description {
    [[self model] addBackgroundTask:description];
}

- (BOOL) tooSoon:(NSDate*) lastDate {
    if (lastDate == nil) {
        return NO;
    }
    
    NSDate* now = [NSDate date];
    NSDateComponents* lastDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSHourCalendarUnit fromDate:lastDate];
    NSDateComponents* nowDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSHourCalendarUnit fromDate:now];
    
    if ([lastDateComponents day] != [nowDateComponents day]) {
        // different days.  we definitely need to refresh
        return NO;
    }
    
    // same day, check if they're at least 8 hours apart.
    if ([nowDateComponents hour] >= ([lastDateComponents hour] + 8)) {
        return NO;
    }
    
    // it's been less than 8 hours.  it's too soon to refresh
    return YES;
}


- (void) spawnRatingsLookupThread {
    NSDate* lastLookupDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[Application ratingsFile:[self.model currentRatingsProvider]]
                                                                               error:NULL] objectForKey:NSFileModificationDate];
    if ([self tooSoon:lastLookupDate]) {
        return;
    }
    
    [self onBackgroundTaskStarted:NSLocalizedString(@"Downloading movie list", nil)];
    [self performSelectorInBackground:@selector(ratingsLookupBackgroundThreadEntryPoint:) withObject:nil];
}

- (void) spawnFullLookupThread {
    if ([Utilities isNilOrEmpty:self.model.postalCode]) {
        return;
    }
    
    if ([self tooSoon:[self.model lastFullUpdateTime]]) {
        return;
    }
    
    [self onBackgroundTaskStarted:NSLocalizedString(@"Downloading ticketing data", nil)];
    [self performSelectorInBackground:@selector(fullLookupBackgroundThreadEntryPoint:) withObject:nil];
}

- (void) spawnBackgroundThreads {
    [self spawnRatingsLookupThread];
    [self spawnFullLookupThread];
}

- (id) initWithAppDelegate:(BoxOfficeAppDelegate*) appDelegate_ {
    if (self = [super init]) {
        appDelegate = appDelegate_;
        self.ratingsLookupLock = [[[NSLock alloc] init] autorelease];
        self.fullLookupLock = [[[NSLock alloc] init] autorelease];
        
        [self spawnBackgroundThreads];
    }
    
    return self;
}

+ (BoxOfficeController*) controllerWithAppDelegate:(BoxOfficeAppDelegate*) appDelegate {
    return [[[BoxOfficeController alloc] initWithAppDelegate:appDelegate] autorelease];
}

- (NSDictionary*) ratingsLookup {
    if ([self.model rottenTomatoesRatings]) {
        return [[RottenTomatoesDownloader downloaderWithModel:self.model] lookupMovieListings];
    } else if ([self.model metacriticRatings]) {
        return [[MetacriticDownloader downloaderWithModel:self.model] lookupMovieListings];
    }
    
    return nil;
}

- (void) ratingsLookupBackgroundThreadEntryPoint:(id) anObject {
    NSAutoreleasePool* autoreleasePool= [[NSAutoreleasePool alloc] init];
    [self.ratingsLookupLock lock];
    {    
        NSDictionary* extraInformation = [self ratingsLookup];
        [self performSelectorOnMainThread:@selector(setSupplementaryData:) withObject:extraInformation waitUntilDone:NO];
    }
    [self.ratingsLookupLock unlock];
    [autoreleasePool release];
}

- (void) onBackgroundTaskEnded:(NSString*) description {
    [self.model removeBackgroundTask:description];
    [appDelegate.tabBarController refresh];    
}

- (void) setSupplementaryData:(NSDictionary*) extraInfo {
    if (extraInfo.count > 0) {
        [self.model setSupplementaryInformation:extraInfo];
    }
    
    [self onBackgroundTaskEnded:NSLocalizedString(@"Finished downloading movie list", nil)];
}

- (NSDictionary*) processShowtimes:(XmlElement*) moviesElement {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    for (XmlElement* movieElement in [moviesElement children]) {
        NSString* movieId = [movieElement attributeValue:@"id"];
        
        XmlElement* performancesElement = [movieElement element:@"performances"];
        
        NSMutableArray* performances = [NSMutableArray array];
        
        for (XmlElement* performanceElement in [performancesElement children]) {
            NSString* showId = [performanceElement attributeValue:@"showid"];
            NSString* time = [performanceElement attributeValue:@"showtime"];
            time = [Theater processShowtime:time];
            
            Performance* performance = [Performance performanceWithIdentifier:showId
                                                                         time:time];
            
            [performances addObject:[performance dictionary]];
        }
        
        [dictionary setObject:performances forKey:movieId];
    }
    
    return dictionary;
}

- (Theater*) processTheaterElement:(XmlElement*) theaterElement {
    NSString* identifier = [theaterElement attributeValue:@"id"];
    NSString* name = [[theaterElement element:@"name"] text];
    NSString* address = [[theaterElement element:@"address1"] text];
    NSString* city = [[theaterElement element:@"city"] text];
    NSString* state = [[theaterElement element:@"state"] text];
    NSString* postalCode = [[theaterElement element:@"postalcode"] text];
    NSString* phone = [[theaterElement element:@"phonenumber"] text];
    NSString* sellsTickets = [theaterElement attributeValue:@"iswired"];
    
    NSString* fullAddress;
    if ([address hasSuffix:@"."]) {
        fullAddress = [NSString stringWithFormat:@"%@ %@, %@ %@", address, city, state, postalCode];
    } else {
        fullAddress = [NSString stringWithFormat:@"%@. %@, %@ %@", address, city, state, postalCode];
    }
    
    XmlElement* moviesElement = [theaterElement element:@"movies"];
    NSDictionary* movieToShowtimesMap = [self processShowtimes:moviesElement];
    
    if (movieToShowtimesMap.count == 0) {
        return nil;
    }
    
    return [Theater theaterWithIdentifier:identifier
                                     name:name
                                  address:fullAddress
                              phoneNumber:phone
                             sellsTickets:sellsTickets
                      movieToShowtimesMap:movieToShowtimesMap];
}

- (NSArray*) processTheatersElement:(XmlElement*) theatersElement {
    NSMutableArray* array = [NSMutableArray array];
    
    for (XmlElement* theaterElement in [theatersElement children]) {
        Theater* theater = [self processTheaterElement:theaterElement];
        
        if (theater != nil) {
            [array addObject:theater];
        }
    }
    
    return array;
}

- (NSArray*) processMoviesElement:(XmlElement*) moviesElement {
    NSMutableArray* array = [NSMutableArray array];
    
    for (XmlElement* movieElement in [moviesElement children]) {
        NSString* identifier = [movieElement attributeValue:@"id"];
        NSString* poster = [movieElement attributeValue:@"posterhref"];
        NSString* title = [[movieElement element:@"title"] text];
        NSString* rating = [[movieElement element:@"rating"] text];
        NSString* length = [[movieElement element:@"runtime"] text];
        NSString* synopsis = [[movieElement element:@"synopsis"] text];
        
        NSString* releaseDateText = [[movieElement element:@"releasedate"] text];
        NSDate* releaseDate = nil;
        if (releaseDateText != nil) {
            releaseDate = [NSDate dateWithNaturalLanguageString:releaseDateText];
        }
        
        Movie* movie = [Movie movieWithIdentifier:identifier
                                            title:title
                                           rating:rating
                                           length:length
                                      releaseDate:releaseDate
                                           poster:poster
                                         synopsis:synopsis];
        
        [array addObject:movie];
    }
    
    return array;
}

- (NSArray*) processElement:(XmlElement*) element {
    XmlElement* dataElement = [element element:@"data"];
    XmlElement* moviesElement = [dataElement element:@"movies"];
    XmlElement* theatersElement = [dataElement element:@"theaters"];
    
    NSArray* theaters = [self processTheatersElement:theatersElement];
    NSArray* movies = [self processMoviesElement:moviesElement];
    
    return [NSArray arrayWithObjects:movies, theaters, nil];
}
 
- (NSArray*) fullLookup {
    if (![Utilities isNilOrEmpty:self.model.postalCode]) {
        NSMutableArray* hosts = [Application hosts];
        NSInteger index = abs([Utilities hashString:self.model.postalCode]) % hosts.count;
        NSString* host = [hosts objectAtIndex:index];
        
        NSDateComponents* components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                                                       fromDate:[self.model searchDate]];
        
        NSString* urlString =[NSString stringWithFormat:
                              @"http://%@.appspot.com/LookupTheaterListings?q=%@&date=%d-%d-%d",
                              host,
                              self.model.postalCode,
                              [components year],
                              [components month],
                              [components day]];
        
        XmlElement* element = [Utilities downloadXml:urlString];
        
        if (element != nil) {
            return [self processElement:element];
        }
    }
    
    return nil;
}

- (void) setMoviesAndTheaters:(NSArray*) moviesAndTheaters {
    NSArray* movies = [moviesAndTheaters objectAtIndex:0];
    NSArray* theaters = [moviesAndTheaters objectAtIndex:1];

    if (movies.count > 0 || theaters.count > 0) {
        [self.model setMovies:movies];
        [self.model setTheaters:theaters];
    }
    
    [self onBackgroundTaskEnded:NSLocalizedString(@"Finished downloading movie and theater data", nil)];
}

- (void) saveArray:(NSArray*) array to:(NSString*) file {
    NSMutableArray* encoded = [NSMutableArray array];
    
    for (id object in array) {
        [encoded addObject:[object dictionary]];
    }
    
    [Utilities writeObject:encoded toFile:file];
}

- (void) fullLookupBackgroundThreadEntryPoint:(id) anObject {    
    [self.fullLookupLock lock];
    {
        NSAutoreleasePool* autoreleasePool= [[NSAutoreleasePool alloc] init];
        
        NSArray* moviesAndTheaters = [self fullLookup];
        NSArray* movies = [moviesAndTheaters objectAtIndex:0];
        NSArray* theaters = [moviesAndTheaters objectAtIndex:1];
        
        if (movies.count > 0 || theaters.count > 0) {
            [self saveArray:movies to:[Application moviesFile]];
            [self saveArray:theaters to:[Application theatersFile]];
        }
        
        [self performSelectorOnMainThread:@selector(setMoviesAndTheaters:) withObject:moviesAndTheaters waitUntilDone:NO];
        
        [autoreleasePool release];
    }
    [self.fullLookupLock unlock];
}

- (void) setSearchDate:(NSDate*) searchDate {
    if ([searchDate isEqual:[self.model searchDate]]) {
        return;
    }
    
    [self.model setSearchDate:searchDate];
    [self spawnBackgroundThreads];
    [appDelegate.tabBarController popNavigationControllers];
    [appDelegate.tabBarController refresh];
}

- (void) setPostalCode:(NSString*) postalCode {
    if ([postalCode isEqual:[self.model postalCode]]) {
        return;
    }

    [self.model setPostalCode:postalCode];
    [self spawnBackgroundThreads];
    [appDelegate.tabBarController popNavigationControllers];
    [appDelegate.tabBarController refresh];
}

- (void) setSearchRadius:(NSInteger) radius {
    [self.model setSearchRadius:radius];
    [appDelegate.tabBarController refresh];
}

- (void) setRatingsProviderIndex:(NSInteger) index {
    if (index == [self.model ratingsProviderIndex]) {
        return;
    }
    
    [self.model setRatingsProviderIndex:index];
    [self spawnRatingsLookupThread];
    [appDelegate.tabBarController refresh];
}

@end