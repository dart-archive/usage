// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.hit_types_test;

import 'package:unittest/unittest.dart';

import 'src/common.dart';

void defineTests() {
  group('screenView', () {
    test('simple', () {
      AnalyticsImplMock mock = createMock();
      mock.sendScreenView('main');
      expect(mock.mockProperties['clientId'], isNotNull);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
    });
  });

  group('event', () {
    test('simple', () {
      AnalyticsImplMock mock = createMock();
      mock.sendEvent('files', 'save');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'event');
      has(mock.last, 'ec');
      has(mock.last, 'ea');
    });
  });

  group('social', () {
    test('simple', () {
      AnalyticsImplMock mock = createMock();
      mock.sendSocial('g+', 'plus', 'userid');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'social');
      has(mock.last, 'sn');
      has(mock.last, 'st');
      has(mock.last, 'sa');
    });
  });

  group('timing', () {
    test('simple', () {
      AnalyticsImplMock mock = createMock();
      mock.sendTiming('compile', 123);
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'timing');
      has(mock.last, 'utv');
      has(mock.last, 'utt');
    });
  });

  group('exception', () {
    test('simple', () {
      AnalyticsImplMock mock = createMock();
      mock.sendException('FooException');
      expect(mock.mockPostHandler.sentValues, isNot(isEmpty));
      was(mock.last, 'exception');
      has(mock.last, 'exd');
    });

    test('exception file paths', () {
      AnalyticsImplMock mock = createMock();
      mock.sendException('foo bar (file:///Users/foobar/tmp/error.dart:3:13)');
      expect(mock.last['exd'], 'foo bar (');
    });
  });
}
