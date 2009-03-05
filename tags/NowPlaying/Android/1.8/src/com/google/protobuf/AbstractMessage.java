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

package com.google.protobuf;

import com.google.protobuf.Descriptors.FieldDescriptor;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;
import java.util.Map;

/**
 * A partial implementation of the {@link Message} interface which implements as many methods of that interface as
 * possible in terms of other methods.
 *
 * @author kenton@google.com Kenton Varda
 */
public abstract class AbstractMessage implements Message {
  @SuppressWarnings("unchecked")
  public boolean isInitialized() {
    // Check that all required fields are present.
    for (final FieldDescriptor field : getDescriptorForType().getFields()) {
      if (field.isRequired()) {
        if (!hasField(field)) {
          return false;
        }
      }
    }

    // Check that embedded messages are initialized.
    for (final Map.Entry<FieldDescriptor, Object> entry : getAllFields().entrySet()) {
      final FieldDescriptor field = entry.getKey();
      if (field.getJavaType() == FieldDescriptor.JavaType.MESSAGE) {
        if (field.isRepeated()) {
          for (final Message element : (List<Message>) entry.getValue()) {
            if (!element.isInitialized()) {
              return false;
            }
          }
        } else {
          if (!((Message) entry.getValue()).isInitialized()) {
            return false;
          }
        }
      }
    }

    return true;
  }

  public final String toString() {
    return TextFormat.printToString(this);
  }

  @SuppressWarnings("unchecked")
  public void writeTo(final CodedOutputStream output) throws IOException {
    for (final Map.Entry<FieldDescriptor, Object> entry : getAllFields().entrySet()) {
      final FieldDescriptor field = entry.getKey();
      if (field.isRepeated()) {
        for (final Object element : (List<Object>) entry.getValue()) {
          output.writeField(field.getType(), field.getNumber(), element);
        }
      } else {
        output.writeField(field.getType(), field.getNumber(), entry.getValue());
      }
    }

    final UnknownFieldSet unknownFields = getUnknownFields();
    if (getDescriptorForType().getOptions().getMessageSetWireFormat()) {
      unknownFields.writeAsMessageSetTo(output);
    } else {
      unknownFields.writeTo(output);
    }
  }

  public ByteString toByteString() {
    try {
      final ByteString.CodedBuilder out = ByteString.newCodedBuilder(getSerializedSize());
      writeTo(out.getCodedOutput());
      return out.build();
    } catch (final IOException e) {
      throw new RuntimeException("Serializing to a ByteString threw an IOException (should " + "never happen).", e);
    }
  }

  public byte[] toByteArray() {
    try {
      final byte[] result = new byte[getSerializedSize()];
      final CodedOutputStream output = CodedOutputStream.newInstance(result);
      writeTo(output);
      output.checkNoSpaceLeft();
      return result;
    } catch (final IOException e) {
      throw new RuntimeException("Serializing to a byte array threw an IOException " + "(should never happen).", e);
    }
  }

  public void writeTo(final OutputStream output) throws IOException {
    final CodedOutputStream codedOutput = CodedOutputStream.newInstance(output);
    writeTo(codedOutput);
    codedOutput.flush();
  }

  private int memoizedSize = -1;

  @SuppressWarnings("unchecked")
  public int getSerializedSize() {
    int size = this.memoizedSize;
    if (size != -1) {
      return size;
    }

    size = 0;
    for (final Map.Entry<FieldDescriptor, Object> entry : getAllFields().entrySet()) {
      final FieldDescriptor field = entry.getKey();
      if (field.isRepeated()) {
        for (final Object element : (List<Object>) entry.getValue()) {
          size += CodedOutputStream.computeFieldSize(field.getType(), field.getNumber(), element);
        }
      } else {
        size += CodedOutputStream.computeFieldSize(field.getType(), field.getNumber(), entry.getValue());
      }
    }

    final UnknownFieldSet unknownFields = getUnknownFields();
    if (getDescriptorForType().getOptions().getMessageSetWireFormat()) {
      size += unknownFields.getSerializedSizeAsMessageSet();
    } else {
      size += unknownFields.getSerializedSize();
    }

    this.memoizedSize = size;
    return size;
  }

  @Override   public boolean equals(final Object other) {
    if (other == this) {
      return true;
    }
    if (!(other instanceof Message)) {
      return false;
    }
    final Message otherMessage = (Message) other;
    if (getDescriptorForType() != otherMessage.getDescriptorForType()) {
      return false;
    }
    return getAllFields().equals(otherMessage.getAllFields());
  }

  @Override   public int hashCode() {
    int hash = 41;
    hash = 19 * hash + getDescriptorForType().hashCode();
    hash = 53 * hash + getAllFields().hashCode();
    return hash;
  }

  // =================================================================

  /**
   * A partial implementation of the {@link Message.Builder} interface which implements as many methods of that
   * interface as possible in terms of other methods.
   */
  @SuppressWarnings("unchecked")
  public static abstract class Builder<BuilderType extends Builder> implements Message.Builder {
    // The compiler produces an error if this is not declared explicitly.
    public abstract BuilderType clone();

    public BuilderType clear() {
      for (final Map.Entry<FieldDescriptor, Object> entry : getAllFields().entrySet()) {
        clearField(entry.getKey());
      }
      return (BuilderType) this;
    }

    public BuilderType mergeFrom(final Message other) {
      if (other.getDescriptorForType() != getDescriptorForType()) {
        throw new IllegalArgumentException("mergeFrom(Message) can only merge messages of the same type.");
      }

      // Note:  We don't attempt to verify that other's fields have valid
      //   types.  Doing so would be a losing battle.  We'd have to verify
      //   all sub-messages as well, and we'd have to make copies of all of
      //   them to insure that they don't change after verification (since
      //   the Message interface itself cannot enforce immutability of
      //   implementations).
      // TODO(kenton):  Provide a function somewhere called makeDeepCopy()
      //   which allows people to make secure deep copies of messages.

      for (final Map.Entry<FieldDescriptor, Object> entry : other.getAllFields().entrySet()) {
        final FieldDescriptor field = entry.getKey();
        if (field.isRepeated()) {
          for (final Object element : (List) entry.getValue()) {
            addRepeatedField(field, element);
          }
        } else if (field.getJavaType() == FieldDescriptor.JavaType.MESSAGE) {
          final Message existingValue = (Message) getField(field);
          if (existingValue == existingValue.getDefaultInstanceForType()) {
            setField(field, entry.getValue());
          } else {
            setField(field, existingValue.newBuilderForType()
                .mergeFrom(existingValue)
                .mergeFrom((Message) entry.getValue())
                .build());
          }
        } else {
          setField(field, entry.getValue());
        }
      }

      return (BuilderType) this;
    }

    public BuilderType mergeFrom(final CodedInputStream input) throws IOException {
      return mergeFrom(input, ExtensionRegistry.getEmptyRegistry());
    }

    public BuilderType mergeFrom(final CodedInputStream input, final ExtensionRegistry extensionRegistry)
        throws IOException {
      final UnknownFieldSet.Builder unknownFields = UnknownFieldSet.newBuilder(getUnknownFields());
      FieldSet.mergeFrom(input, unknownFields, extensionRegistry, this);
      setUnknownFields(unknownFields.build());
      return (BuilderType) this;
    }

    public BuilderType mergeUnknownFields(final UnknownFieldSet unknownFields) {
      setUnknownFields(UnknownFieldSet.newBuilder(getUnknownFields())
          .mergeFrom(unknownFields)
          .build());
      return (BuilderType) this;
    }

    public BuilderType mergeFrom(final ByteString data) throws InvalidProtocolBufferException {
      try {
        final CodedInputStream input = data.newCodedInput();
        mergeFrom(input);
        input.checkLastTagWas(0);
        return (BuilderType) this;
      } catch (final InvalidProtocolBufferException e) {
        throw e;
      } catch (final IOException e) {
        throw new RuntimeException("Reading from a ByteString threw an IOException (should " + "never happen).", e);
      }
    }

    public BuilderType mergeFrom(final ByteString data, final ExtensionRegistry extensionRegistry)
        throws InvalidProtocolBufferException {
      try {
        final CodedInputStream input = data.newCodedInput();
        mergeFrom(input, extensionRegistry);
        input.checkLastTagWas(0);
        return (BuilderType) this;
      } catch (final InvalidProtocolBufferException e) {
        throw e;
      } catch (final IOException e) {
        throw new RuntimeException("Reading from a ByteString threw an IOException (should " + "never happen).", e);
      }
    }

    public BuilderType mergeFrom(final byte[] data) throws InvalidProtocolBufferException {
      try {
        final CodedInputStream input = CodedInputStream.newInstance(data);
        mergeFrom(input);
        input.checkLastTagWas(0);
        return (BuilderType) this;
      } catch (final InvalidProtocolBufferException e) {
        throw e;
      } catch (final IOException e) {
        throw new RuntimeException("Reading from a byte array threw an IOException (should " + "never happen).", e);
      }
    }

    public BuilderType mergeFrom(final byte[] data, final ExtensionRegistry extensionRegistry)
        throws InvalidProtocolBufferException {
      try {
        final CodedInputStream input = CodedInputStream.newInstance(data);
        mergeFrom(input, extensionRegistry);
        input.checkLastTagWas(0);
        return (BuilderType) this;
      } catch (final InvalidProtocolBufferException e) {
        throw e;
      } catch (final IOException e) {
        throw new RuntimeException("Reading from a byte array threw an IOException (should " + "never happen).", e);
      }
    }

    public BuilderType mergeFrom(final InputStream input) throws IOException {
      final CodedInputStream codedInput = CodedInputStream.newInstance(input);
      mergeFrom(codedInput);
      codedInput.checkLastTagWas(0);
      return (BuilderType) this;
    }

    public BuilderType mergeFrom(final InputStream input, final ExtensionRegistry extensionRegistry)
        throws IOException {
      final CodedInputStream codedInput = CodedInputStream.newInstance(input);
      mergeFrom(codedInput, extensionRegistry);
      codedInput.checkLastTagWas(0);
      return (BuilderType) this;
    }
  }
}
