// Copyright 2008 Cyrus Najmabadi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "Score.h"

#import "Movie.h"
#import "Utilities.h"

@implementation Score

property_definition(canonicalTitle);
property_definition(synopsis);
property_definition(score);
property_definition(provider);
property_definition(identifier);

- (void) dealloc {
    self.canonicalTitle = nil;
    self.synopsis = nil;
    self.score = nil;
    self.provider = nil;
    self.identifier = nil;
    
    [super dealloc];
}


- (id) initWithCanonicalTitle:(NSString*) canonicalTitle_
                     synopsis:(NSString*) synopsis_
                        score:(NSString*) score_
                     provider:(NSString*) provider_
                   identifier:(NSString*) identifier_ {
    if (self = [super init]) {
        self.canonicalTitle = [Utilities nonNilString:canonicalTitle_];
        self.score = [Utilities nonNilString:score_];
        self.synopsis = [Utilities nonNilString:synopsis_];
        self.provider = provider_;
        self.identifier = [Utilities nonNilString:identifier_];
    }
    
    return self;
}


+ (Score*) scoreWithTitle:(NSString*) title
                        synopsis:(NSString*) synopsis
                           score:(NSString*) score
                        provider:(NSString*) provider
                      identifier:(NSString*) identifier {
    return [[[Score alloc] initWithCanonicalTitle:[Movie makeCanonical:title]
                                               synopsis:[Utilities stripHtmlCodes:synopsis]
                                                  score:score
                                               provider:provider
                                             identifier:identifier] autorelease];
}


+ (Score*) scoreWithDictionary:(NSDictionary*) dictionary {
    return [[[Score alloc] initWithCanonicalTitle:[dictionary objectForKey:canonicalTitle_key]
                                               synopsis:[dictionary objectForKey:synopsis_key]
                                                  score:[dictionary objectForKey:score_key]
                                               provider:[dictionary objectForKey:provider_key]
                                             identifier:[dictionary objectForKey:identifier_key]] autorelease];
}


- (NSDictionary*) dictionary {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:canonicalTitle    forKey:canonicalTitle_key];
    [dictionary setObject:synopsis          forKey:synopsis_key];
    [dictionary setObject:score             forKey:score_key];
    [dictionary setObject:provider          forKey:provider_key];
    [dictionary setObject:identifier        forKey:identifier_key];
    return dictionary;
}


- (NSInteger) scoreValue {
    int value = score.intValue;
    if (value >= 0 && value <= 100) {
        return value;
    }
    
    return -1;
}


@end