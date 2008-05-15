//
//  Application.m
//  BoxOfficeApplication
//
//  Created by Cyrus Najmabadi on 4/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Application.h"


@implementation Application

static NSRecursiveLock* gate = nil;
static NSString* _supportFolder = nil;
static NSString* _postersFolder = nil;
static NSString* _documentsFolder = nil;
static NSDateFormatter* dateFormatter = nil;
static UIColor* lightBlueTextColor = nil;
static UIImage* freshImage = nil;
static UIImage* rottenImage = nil;

+ (void) initialize {
    if (self == [Application class]) {
        gate = [[NSRecursiveLock alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        lightBlueTextColor = [UIColor colorWithRed:0.32 green:0.4 blue:0.55 alpha:1];
        [lightBlueTextColor retain];
        
        freshImage = [UIImage imageNamed:@"Fresh.png"];
        rottenImage = [UIImage imageNamed:@"Rotten.png"];
        [freshImage retain];
        [rottenImage retain];
    }
}

+ (void) createDirectory:(NSString*) folder {
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
    }    
}

+ (NSString*) documentsFolder {
    [gate lock];
    {
        if (_documentsFolder == nil) {
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, /*expandTilde:*/YES);
            NSString* folder = [paths objectAtIndex:0];
            
            [Application createDirectory:folder];
            
            _documentsFolder = folder;
            [_documentsFolder retain];
        }
    }
    [gate unlock];
    
    return _documentsFolder;
}

+ (NSString*) supportFolder {
    [gate lock];
    {
        if (_supportFolder == nil) {
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, /*expandTilde:*/YES);
            
            NSString* executableName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
            NSString* folder = [[paths objectAtIndex:0] stringByAppendingPathComponent:executableName];
            
            [Application createDirectory:folder];
            
            _supportFolder = folder;
            [_supportFolder retain];
        }
    }
    [gate unlock];
    
    return _supportFolder;
}

+ (NSString*) postersFolder {
    [gate lock];
    {
        if (_postersFolder == nil) {
            NSString* parent = [Application supportFolder];
            NSString* folder = [parent stringByAppendingPathComponent:@"Posters"];
            
            [Application createDirectory:folder];
            
            _postersFolder = folder;
            [_postersFolder retain];
        }
    }
    [gate unlock];
    
    return _postersFolder;
}

+ (NSString*) formatDate:(NSDate*) date {
    NSString* result;
    [gate lock];
    {
        result = [dateFormatter stringFromDate:date];
    }
    [gate unlock];
    return result;
}

+ (UIColor*) lightBlueTextColor {
    return lightBlueTextColor;
}

+ (UIImage*) freshImage {
    return freshImage;
}

+ (UIImage*) rottenImage {
    return rottenImage;
}

@end
