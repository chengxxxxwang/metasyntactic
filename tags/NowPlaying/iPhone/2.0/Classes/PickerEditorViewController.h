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

#import "EditorViewController.h"

@interface PickerEditorViewController : EditorViewController<UIPickerViewDelegate> {
    UIPickerView* picker;
    NSArray* values;
    UILabel* label;
}

@property (retain) UIPickerView* picker;
@property (retain) NSArray* values;
@property (retain) UILabel* label;

- (id) initWithController:(AbstractNavigationController*) navigationController
                    title:(NSString*) title
                     text:(NSString*) text
                   object:(id) object
                 selector:(SEL) selector
                   values:(NSArray*) values
             defaultValue:(NSString*) defaultValue;

@end