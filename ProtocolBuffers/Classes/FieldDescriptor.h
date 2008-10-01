// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.
// http://code.google.com/p/protobuf/
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GenericDescriptor.h"

#import "FieldDescriptorType.h"
#import "ObjectiveCType.h"

@interface PBFieldDescriptor : NSObject/*<PBGenericDescriptor>*/ {
}

- (BOOL) isRequired;
- (BOOL) isRepeated;
- (BOOL) isExtension;
- (BOOL) isOptional;
- (ObjectiveCType) getObjectiveCType;
- (FieldDescriptorType) getType;

- (PBDescriptor*) getContainingType;
- (PBDescriptor*) getExtensionScope;
- (PBDescriptor*) getMessageType;
- (PBEnumDescriptor*) getEnumType;

- (id) getDefaultValue;
- (int32_t) getIndex;
- (int32_t) getNumber;

- (NSString*) getFullName;


#if 0
    int32_t index;
    FieldDescriptorProto* proto;
    NSString* fullName;
    PBFileDescriptor* file;
    Type* type;
    PBDescriptor* containingType;
}

@property int32_t index;
@property (retain) FieldDescriptorProto* proto;
@property (retain) NSString* fullName;
@property (retain) PBFileDescriptor* file;
@property (retain) Type* type;
@property (retain) PBDescriptor* containingType;

- (NSString*) name;

- (BOOL) hasDefaultValue;
- (FieldOptions*) options;

- (PBDescriptor*) extensionScope;
- (PBDescriptor*) messageType;
#endif

@end