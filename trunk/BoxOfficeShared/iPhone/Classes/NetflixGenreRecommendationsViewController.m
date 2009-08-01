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

#import "NetflixGenreRecommendationsViewController.h"

#import "CommonNavigationController.h"
#import "Model.h"
#import "Movie.h"
#import "MutableNetflixCache.h"
#import "NetflixCell.h"
#import "Queue.h"

@interface NetflixGenreRecommendationsViewController()
@property (retain) NetflixAccount* account;
@property (copy) NSString* genre;
@property (retain) NSArray* movies;
@end


@implementation NetflixGenreRecommendationsViewController

@synthesize account;
@synthesize genre;
@synthesize movies;

- (void) dealloc {
  self.account = nil;
  self.genre = nil;
  self.movies = nil;

  [super dealloc];
}


- (id) initWithGenre:(NSString*) genre_ {
  if ((self = [super initWithStyle:UITableViewStylePlain])) {
    self.genre = genre_;
    self.title = genre_;
  }

  return self;
}


- (Model*) model {
  return [Model model];
}


- (void) onBeforeReloadTableViewData {
  [super onBeforeReloadTableViewData];
  self.account = self.model.currentNetflixAccount;

  self.tableView.rowHeight = 100;
  NSMutableArray* array = [NSMutableArray array];

  Queue* queue = [self.model.netflixCache queueForKey:[NetflixCache recommendationKey] account:account];
  for (Movie* movie in queue.movies) {
    NSArray* genres = movie.genres;
    if (genres.count > 0 && [genre isEqual:[genres objectAtIndex:0]]) {
      [array addObject:movie];
    }
  }

  self.movies = array;
}


- (void) didReceiveMemoryWarningWorker {
  [super didReceiveMemoryWarningWorker];
  self.movies = [NSArray array];
}


- (NSInteger) numberOfSectionsInTableView:(UITableView*) tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
  return movies.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell*) tableView:(UITableView*) tableView_
         cellForRowAtIndexPath:(NSIndexPath*) indexPath {
  static NSString* reuseIdentifier = @"reuseIdentifier";
  NetflixCell* cell = (id)[self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (cell == nil) {
    cell = [[[NetflixCell alloc] initWithReuseIdentifier:reuseIdentifier] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }

  Movie* movie = [movies objectAtIndex:indexPath.row];
  [cell setMovie:movie owner:self];

  return cell;
}


- (CommonNavigationController*) commonNavigationController {
  return (id) self.navigationController;
}


- (void)            tableView:(UITableView*) tableView
      didSelectRowAtIndexPath:(NSIndexPath*) indexPath {
  Movie* movie = [movies objectAtIndex:indexPath.row];
  [self.commonNavigationController pushMovieDetails:movie animated:YES];
}


- (NSString*)       tableView:(UITableView*) tableView
      titleForHeaderInSection:(NSInteger) section {
  if (movies.count == 0) {
    return self.model.netflixCache.noInformationFound;
  }

  return nil;
}

@end
