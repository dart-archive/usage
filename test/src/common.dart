// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.common_test;

import 'dart:async';

import 'package:usage/src/usage_impl.dart';

class AnalyticsImplMock extends AnalyticsImpl {
  MockProperties get mockProperties => properties;
  MockPostHandler get mockPostHandler => postHandler;

  AnalyticsImplMock(String trackingId) :
    super(trackingId, new MockProperties(), new MockPostHandler()) {
    optIn = true;
  }

  Map<String, dynamic> get last => mockPostHandler.last;
}

class MockProperties extends PersistentProperties {
  Map<String, dynamic> props = {};

  MockProperties() : super('mock');

  dynamic operator[](String key) => props[key];

  void operator[]=(String key, dynamic value) {
    props[key] = value;
  }
}

class MockPostHandler extends PostHandler {
  List<Map> sentValues = [];

  Future sendPost(String url, Map<String, String> parameters) {
    sentValues.add(parameters);

    return new Future.value();
  }

  Map<String, dynamic> get last => sentValues.last;
}
