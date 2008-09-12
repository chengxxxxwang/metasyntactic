package org.metasyntactic.utilities;

/** @author cyrusn@google.com (Cyrus Najmabadi) */
public class StringUtilities {
  private StringUtilities() {

  }


  public static boolean isNullOrEmpty(String address) {
    return address == null || address.length() == 0;
  }
}
