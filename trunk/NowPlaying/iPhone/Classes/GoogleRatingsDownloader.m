//
//  GoogleRatingsDownloader.m
//  NowPlaying
//
//  Created by Cyrus Najmabadi on 9/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GoogleRatingsDownloader.h"

#import "Application.h"
#import "DateUtilities.h"
#import "ExtraMovieInformation.h"
#import "Location.h"
#import "NetworkUtilities.h"
#import "NowPlayingModel.h"
#import "UserLocationCache.h"
#import "Utilities.h"
#import "XmlElement.h"

@implementation GoogleRatingsDownloader

@synthesize model;

- (void) dealloc {
    self.model = nil;
    [super dealloc];
}


- (id) initWithModel:(NowPlayingModel*) model_ {
    if (self = [super init]) {
        self.model = model_;
    }
    
    return self;
}


+ (GoogleRatingsDownloader*) downloaderWithModel:(NowPlayingModel*) model {
    return [[[GoogleRatingsDownloader alloc] initWithModel:model] autorelease];
}


+ (NSString*) serverUrl:(NowPlayingModel*) model {
    Location* location = [model.userLocationCache locationForUserAddress:model.userAddress];
    
    if (location.postalCode == nil) {
        return nil;
    }
    
    NSString* country = location.country.length == 0 ? [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]
                                                     : location.country;
    
    
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit
                                                                   fromDate:[DateUtilities today]
                                                                     toDate:model.searchDate
                                                                    options:0];
    NSInteger day = components.day;
    day = MIN(MAX(day, 0), 7);
    
    NSString* address = [NSString stringWithFormat:
                         @"http://metaboxoffice6.appspot.com/LookupTheaterListings?country=%@&language=%@&postalcode=%@&day=%d&format=xml&latitude=%d&longitude=%d",
                         country,
                         [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode],
                         [Utilities stringByAddingPercentEscapes:location.postalCode],
                         day,
                         (int)(location.latitude * 1000000),
                         (int)(location.longitude * 1000000)];
    
    return address;
}


+ (NSString*) lookupServerHash:(NowPlayingModel*) model {
    NSString* baseAddress = [self serverUrl:model];
    NSString* address = [baseAddress stringByAppendingString:@"&hash=true"];
    NSString* value = [NetworkUtilities stringWithContentsOfAddress:address
                                                          important:YES];
    return value;
}


- (NSDictionary*) lookupMovieListings {
    NSString* address = [GoogleRatingsDownloader serverUrl:self.model];
    XmlElement* resultElement = [NetworkUtilities xmlWithContentsOfAddress:address
                                                                 important:YES];
    XmlElement* moviesElement = [resultElement element:@"Movies"];
    
    if (moviesElement != nil) {
        NSMutableDictionary* ratings = [NSMutableDictionary dictionary];

        for (XmlElement* movieElement in moviesElement.children) {
            NSString* identifier = [movieElement attributeValue:@"identifier"];
            NSString* title = [movieElement attributeValue:@"title"];
            NSString* score = [movieElement attributeValue:@"score"];
            if (score.length == 0) {
                score = @"-1";
            }
            
            ExtraMovieInformation* info = [ExtraMovieInformation infoWithTitle:title
                                                                      synopsis:@""
                                                                         score:score
                                                                      provider:@"google"
                                                                    identifier:identifier];
            
            [ratings setObject:info forKey:info.canonicalTitle];
        }
        
        return ratings;
    }
    
    return nil;
}


- (NSString*) ratingsFile {
    return [Application ratingsFile:[self.model.ratingsProviders objectAtIndex:2]];
}

@end
