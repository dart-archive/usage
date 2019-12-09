// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.common_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:usage/src/usage_impl.dart';

AnalyticsImplMock createMock({Map<String, dynamic> props}) =>
    AnalyticsImplMock('UA-0', props: props);

void was(Map m, String type) => expect(m['t'], type);
void has(Map m, String key) => expect(m[key], isNotNull);
void hasnt(Map m, String key) => expect(m[key], isNull);

class AnalyticsImplMock extends AnalyticsImpl {
  MockProperties get mockProperties => properties;
  MockPostHandler get mockPostHandler => postHandler;

  AnalyticsImplMock(String trackingId, {Map<String, dynamic> props})
      : super(trackingId, MockProperties(props), MockPostHandler(),
            applicationName: 'Test App', applicationVersion: '0.1');

  Map<String, dynamic> get last => mockPostHandler.last;
}

class MockProperties extends PersistentProperties {
  Map<String, dynamic> props = {};

  MockProperties([Map<String, dynamic> props]) : super('mock') {
    if (props != null) this.props.addAll(props);
  }

  @override
  dynamic operator [](String key) => props[key];

  @override
  void operator []=(String key, dynamic value) {
    props[key] = value;
  }

  @override
  void syncSettings() {}
}

class MockPostHandler extends PostHandler {
  List<Map<String, dynamic>> sentValues = [];

  @override
  Future sendPost(String url, Map<String, dynamic> parameters) {
    sentValues.add(parameters);

    return Future.value();
  }

  Map<String, dynamic> get last => sentValues.last;

  @override
  void close() {}
}
