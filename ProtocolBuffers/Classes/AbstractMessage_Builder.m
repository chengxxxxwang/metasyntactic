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

#import "AbstractMessage_Builder.h"

#import "Descriptor.pb.h"

#import "CodedInputStream.h"
#import "ExtensionRegistry.h"
#import "FieldDescriptor.h"
#import "FieldSet.h"
#import "UnknownFieldSet.h"
#import "UnknownFieldSet_Builder.h"


@implementation AbstractMessage_Builder


- (id<PBMessage_Builder>) clone {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) clear {
    for (PBFieldDescriptor* key in self.getAllFields) {
        [self clearField:key];
    }

    return self;
}


- (id<PBMessage_Builder>) mergeFromMessage:(id<Message>) other {
    if ([other getDescriptorForType] != self.getDescriptorForType) {
        @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"mergeFromMessage:(id<Message>) can only merge messages of the same type." userInfo:nil];
    }

    // Note:  We don't attempt to verify that other's fields have valid
    //   types.  Doing so would be a losing battle.  We'd have to verify
    //   all sub-messages as well, and we'd have to make copies of all of
    //   them to insure that they don't change after verification (since
    //   the Message interface itself cannot enforce immutability of
    //   implementations).
    // TODO(kenton):  Provide a function somewhere called makeDeepCopy()
    //   which allows people to make secure deep copies of messages.
    NSDictionary* allFields = self.getAllFields;
    for (PBFieldDescriptor* field in allFields) {
        id value = [allFields objectForKey:field];

        if (field.isRepeated) {
            for (id element in value) {
                [self addRepeatedField:field value:element];
            }
        } else if (field.getObjectiveCType == ObjectiveCTypeMessage) {
            id<Message> existingValue = [self getField:field];

            if (existingValue == [existingValue getDefaultInstanceForType]) {
                [self setField:field value:value];
            } else {
                id value1 = [[[[existingValue newBuilderForType] mergeFromMessage:existingValue] mergeFromMessage:value] build];
                [self setField:field value:value1];
            }
        } else {
            [self setField:field value:value];
        }
    }

    return self;
}


- (id<PBMessage_Builder>) mergeFromCodedInputStream:(PBCodedInputStream*) input {
    return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry getEmptyRegistry]];
}


- (id<PBMessage_Builder>) mergeFromCodedInputStream:(PBCodedInputStream*) input
                                extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
    PBUnknownFieldSet_Builder* unknownFields = [PBUnknownFieldSet newBuilder:self.getUnknownFields];
    [PBFieldSet mergeFromCodedInputStream:input unknownFields:unknownFields extensionRegistry:extensionRegistry builder:self];
    [self setUnknownFields:[unknownFields build]];

    return self;
}


- (id<PBMessage_Builder>) mergeUnknownFields:(PBUnknownFieldSet*) unknownFields {
    PBUnknownFieldSet* merged = [[[PBUnknownFieldSet newBuilder:self.getUnknownFields] mergeUnknownFields:unknownFields] build];
    [self setUnknownFields:merged];

    return self;
}


- (id<PBMessage_Builder>) mergeFromData:(NSData*) data {
    PBCodedInputStream* input = [PBCodedInputStream streamWithData:data];
    [self mergeFromCodedInputStream:input];
    [input checkLastTagWas:0];
    return self;
}


- (id<PBMessage_Builder>) mergeFromData:(NSData*) data
                    extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
    PBCodedInputStream* input = [PBCodedInputStream streamWithData:data];
    [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
    [input checkLastTagWas:0];
    return self;
}


- (id<PBMessage_Builder>) mergeFromInputStream:(NSInputStream*) input {
    PBCodedInputStream* codedInput = [PBCodedInputStream streamWithInputStream:input];
    [self mergeFromCodedInputStream:codedInput];
    [codedInput checkLastTagWas:0];
    return self;
}


- (id<PBMessage_Builder>) mergeFromInputStream:(NSInputStream*) input
                           extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
    PBCodedInputStream* codedInput = [PBCodedInputStream streamWithInputStream:input];
    [self mergeFromCodedInputStream:codedInput extensionRegistry:extensionRegistry];
    [codedInput checkLastTagWas:0];
    return self;
}


- (id<Message>) buildParsed {
    if (![self isInitialized]) {
        @throw [NSException exceptionWithName:@"UninitializedMessage" reason:@"" userInfo:nil];
    }
    return [self buildPartial];
}


- (id<Message>) build {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<Message>) buildPartial {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (BOOL) isInitialized {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (PBDescriptor*) getDescriptorForType {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<Message>) getDefaultInstanceForType {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (NSDictionary*) getAllFields {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) newBuilderForField:(PBFieldDescriptor*) field {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (BOOL) hasField:(PBFieldDescriptor*) field {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id) getField:(PBFieldDescriptor*) field {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) setField:(PBFieldDescriptor*) field value:(id) value {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) clearField:(PBFieldDescriptor*) field {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (int32_t) getRepeatedFieldCount:(PBFieldDescriptor*) field {
    @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
}


- (id) getRepeatedField:(PBFieldDescriptor*) field index:(int32_t) index {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) setRepeatedField:(PBFieldDescriptor*) field index:(int32_t) index value:(id) value {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) addRepeatedField:(PBFieldDescriptor*) field value:(id) value {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (PBUnknownFieldSet*) unknownFields {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<PBMessage_Builder>) setUnknownFields:(PBUnknownFieldSet*) unknownFields {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (PBUnknownFieldSet*) getUnknownFields {
    @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


@end
