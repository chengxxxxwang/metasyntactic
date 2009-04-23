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

#import "AbstractPosterCell.h"

#import "GlobalActivityIndicator.h"
#import "ImageCache.h"
#import "NowPlayingModel.h"


@interface AbstractPosterCell()
@property ImageState state;
@property (retain) NowPlayingModel* model;
@property (retain) UIImageView* imageLoadingView;
@property (retain) UIImageView* imageView;
@property (retain) UIActivityIndicatorView* activityView;
@end


@implementation AbstractPosterCell

@synthesize state;
@synthesize model;
@synthesize movie;
@synthesize imageLoadingView;
@synthesize imageView;
@synthesize activityView;

- (void) dealloc {
    self.model = nil;
    self.movie = nil;
    self.imageLoadingView = nil;
    self.imageView = nil;
    self.activityView = nil;

    [super dealloc];
}


- (id) initWithFrame:(CGRect) frame
     reuseIdentifier:(NSString*) reuseIdentifier
               model:(NowPlayingModel*) model_ {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.model = model_;

        state = Loading;
        self.imageLoadingView = [[[UIImageView alloc] initWithImage:[ImageCache imageLoading]] autorelease];
        imageLoadingView.contentMode = UIViewContentModeScaleAspectFit;

        self.imageView = [[[UIImageView alloc] init] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.alpha = 0;

        CGRect imageFrame = imageLoadingView.frame;
        imageFrame.size.width = (int)(imageFrame.size.width * SMALL_POSTER_HEIGHT / imageFrame.size.height);
        imageFrame.size.height = (int)SMALL_POSTER_HEIGHT;
        imageView.frame = imageLoadingView.frame = imageFrame;

        self.activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        activityView.hidesWhenStopped = YES;
        CGRect frame = activityView.frame;
        frame.origin.x = 25;
        frame.origin.y = 40;
        activityView.frame = frame;

        [self.contentView addSubview:imageLoadingView];
        [self.contentView addSubview:imageView];
        [self.contentView addSubview:activityView];
    }

    return self;
}


- (void) loadImage {
    if (state == Loaded) {
        // we're done.  nothing else to do.
        return;
    }

    UIImage* image = [model smallPosterForMovie:movie];
    if (image == nil) {
        if ([GlobalActivityIndicator hasBackgroundTasks]) {
            // don't need to do anything.
            // keep up the spinner
            state = Loading;
        } else {
            state = NotFound;
        }
    } else {
        state = Loaded;
    }

    switch (state) {
        case Loading: {
            [activityView startAnimating];
            imageView.image = nil;
            imageView.alpha = 0;
            return;
        }
        case Loaded: {
            [activityView stopAnimating];
            imageView.image = image;
            break;
        }
        case NotFound: {
            [activityView stopAnimating];
            imageView.image = [ImageCache imageNotAvailable];
            break;
        }
    }

    [UIView beginAnimations:nil context:NULL];
    {
        imageLoadingView.alpha = 0;
        imageView.alpha = 1;
    }
    [UIView commitAnimations];
}


- (void) clearImage {
    [activityView startAnimating];

    state = Loading;
    imageView.image = nil;
    imageView.alpha = 0;
    imageLoadingView.alpha = 1;
}


@end