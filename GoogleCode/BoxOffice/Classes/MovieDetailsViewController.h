//
//  MovieDetailsViewController.h
//  BoxOffice
//
//  Created by Cyrus Najmabadi on 4/30/08.
//  Copyright 2008 Metasyntactic. All rights reserved.
//

#import "Movie.h"
#import "BoxOfficeModel.h"

@class MoviesNavigationController;

@interface MovieDetailsViewController : UITableViewController {
    MoviesNavigationController* navigationController;
    
    Movie* movie;
    NSArray* theatersArray;
    NSMutableArray* showtimesArray;
    NSArray* trailersArray;
    
    NSInteger hiddenTheaterCount;
}

@property (assign) MoviesNavigationController* navigationController;
@property (retain) Movie* movie;
@property (retain) NSArray* theatersArray;
@property (retain) NSMutableArray* showtimesArray;
@property (retain) NSArray* trailersArray;
@property NSInteger hiddenTheaterCount;

- (id) initWithNavigationController:(MoviesNavigationController*) navigationController
                              movie:(Movie*) movie;

- (void) refresh;
- (BoxOfficeModel*) model;

@end
