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

#import "Location.h"

#import "Application.h"

@implementation Location

property_definition(latitude);
property_definition(longitude);
property_definition(address);
property_definition(city);
property_definition(state);
property_definition(postalCode);
property_definition(country);

- (void) dealloc {
    self.latitude = 0;
    self.longitude = 0;
    self.address = nil;
    self.city = nil;
    self.state = nil;
    self.postalCode = nil;
    self.country = nil;

    [super dealloc];
}


- (id) initWithLatitude:(double) latitude_
              longitude:(double) longitude_
                address:(NSString*) address_
                   city:(NSString*) city_
                  state:(NSString*) state_
             postalCode:(NSString*) postalCode_
                country:(NSString*) country_ {
    if (self = [super init]) {
        latitude        = latitude_;
        longitude       = longitude_;
        self.address    = (address_ == nil    ? @"" : address_);
        self.city       = (city_ == nil       ? @"" : city_);
        self.state      = (state_ == nil      ? @"" : state_);
        self.postalCode = (postalCode_ == nil ? @"" : postalCode_);
        self.country    = (country_ == nil    ? @"" : country_);

        if ([country isEqual:@"US"] && [postalCode rangeOfString:@"-"].length > 0) {
            NSRange range = [postalCode rangeOfString:@"-"];
            self.postalCode = [postalCode substringToIndex:range.location];
        }
    }

    return self;
}


+ (Location*) locationWithDictionary:(NSDictionary*) dictionary {
    return [self locationWithLatitude:[[dictionary objectForKey:latitude_key] doubleValue]
                            longitude:[[dictionary objectForKey:longitude_key] doubleValue]
                              address:[dictionary objectForKey:address_key]
                                 city:[dictionary objectForKey:city_key]
                                state:[dictionary objectForKey:state_key]
                           postalCode:[dictionary objectForKey:postalCode_key]
                              country:[dictionary objectForKey:country_key]];
}


+ (Location*) locationWithLatitude:(double) latitude
                         longitude:(double) longitude
                           address:(NSString*) address
                              city:(NSString*) city
                             state:(NSString*) state
                        postalCode:(NSString*) postalCode
                           country:(NSString*) country{
    return [[[Location alloc] initWithLatitude:latitude
                                     longitude:longitude
                                       address:address
                                          city:city
                                         state:state
                                    postalCode:postalCode
                                       country:country] autorelease];
}


- (NSDictionary*) dictionary {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithDouble:latitude]    forKey:latitude_key];
    [dict setObject:[NSNumber numberWithDouble:longitude]   forKey:longitude_key];
    [dict setObject:address                                 forKey:address_key];
    [dict setObject:city                                    forKey:city_key];
    [dict setObject:state                                   forKey:state_key];
    [dict setObject:postalCode                              forKey:postalCode_key];
    [dict setObject:country                                 forKey:country_key];
    return dict;
}

- (double) distanceTo:(Location*) to {
    const double GREAT_CIRCLE_RADIUS_KILOMETERS = 6371.797;
    const double GREAT_CIRCLE_RADIUS_MILES = 3438.461;

    if (to == nil) {
        return UNKNOWN_DISTANCE;
    }

    double lat1 = (self.latitude / 180) * M_PI;
    double lng1 = (self.longitude / 180) * M_PI;
    double lat2 = (to.latitude / 180) * M_PI;
    double lng2 = (to.longitude / 180) * M_PI;

    double diff = lng1 - lng2;

    if (diff < 0) { diff = -diff; }
    if (diff > M_PI) { diff = 2 * M_PI; }

    double distance =
    acos(sin(lat2) * sin(lat1) +
         cos(lat2) * cos(lat1) * cos(diff));

    if ([Application useKilometers]) {
        distance *= GREAT_CIRCLE_RADIUS_KILOMETERS;
    } else {
        distance *= GREAT_CIRCLE_RADIUS_MILES;
    }

    if (distance > 200) {
        return UNKNOWN_DISTANCE;
    }

    return distance;
}


- (BOOL) isEqual:(id) anObject {
    Location* other = anObject;

    return latitude == other.latitude &&
           longitude == other.longitude;
}


- (NSUInteger) hash {
    double hash = latitude + longitude;

    return *(NSUInteger*)&hash;
}


- (NSString*) description {
    return [NSString stringWithFormat:@"(%d,%d)", latitude, longitude];
}


@end