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

#import "QuestionCell.h"

#import "BoxOfficeStockImages.h"

@interface QuestionCell()
@property (retain) UILabel* contentLabel;
@end


@implementation QuestionCell

@synthesize contentLabel;

- (void) dealloc {
  self.contentLabel = nil;
  [super dealloc];
}


+ (UIFont*) contentFont {
  return [UIFont systemFontOfSize:16];
}


- (id) initWithQuestion:(BOOL) question
        reuseIdentifier:(NSString*) reuseIdentifier
    tableViewController:(UITableViewController*) tableViewController {
  if ((self = [super initWithStyle:UITableViewCellStyleDefault
                   reuseIdentifier:reuseIdentifier
               tableViewController:tableViewController])) {
    self.backgroundColor = [ColorCache helpBlue];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.contentLabel = [[[UILabel alloc] init] autorelease];
    contentLabel.font = [QuestionCell contentFont];
    contentLabel.numberOfLines = 0;
    contentLabel.lineBreakMode = UILineBreakModeWordWrap;
    contentLabel.backgroundColor = [UIColor clearColor];
    [contentLabel sizeToFit];

    CGRect contentFrame = contentLabel.frame;
    contentFrame.origin.y = 4;
    contentFrame.origin.x = question ? 75 : 20;
    contentLabel.frame = contentFrame;

    [self.contentView addSubview:contentLabel];

    if (question) {
      UIImage* image = BoxOfficeStockImage(@"QuestionBalloon.png");
      UIImage* stretchedImage = [image stretchableImageWithLeftCapWidth:85 topCapHeight:18];
      self.backgroundView = [[[UIImageView alloc] initWithImage:stretchedImage] autorelease];
    } else {
      UIImage* image = BoxOfficeStockImage(@"AnswerBalloon.png");
      UIImage* stretchedImage = [image stretchableImageWithLeftCapWidth:85 topCapHeight:18];
      self.backgroundView = [[[UIImageView alloc] initWithImage:stretchedImage] autorelease];
    }
  }

  return self;
}


- (void) setQuestionText:(NSString*) text {
  contentLabel.text = text;
}


- (CGFloat) height {
  CGFloat width = self.tableViewController.view.frame.size.width;

  width -= (50 + 60);

  CGSize contentSize = [contentLabel.text sizeWithFont:[QuestionCell contentFont]
                        constrainedToSize:CGSizeMake(width, 2000)
                            lineBreakMode:UILineBreakModeWordWrap];

  return contentSize.height + 4 + 8;
}


- (void) layoutSubviews {
  [super layoutSubviews];

  CGFloat height = [self height];

  CGRect contentFrame = contentLabel.frame;
  contentFrame.size.width = self.contentView.frame.size.width - (30 + 60);
  contentFrame.size.height = height - (4 + 8);

  contentLabel.frame = contentFrame;
}

@end