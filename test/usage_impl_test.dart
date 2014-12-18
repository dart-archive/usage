// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.impl_test;

import 'package:unittest/unittest.dart';
import 'package:usage/src/usage_impl.dart';

import 'src/common.dart';

void defineTests() {
  group('ThrottlingBucket', () {
    test('can send', () {
      ThrottlingBucket bucket = new ThrottlingBucket(20);
      expect(bucket.removeDrop(), true);
    });

    test('doesn\'t send too many', () {
      ThrottlingBucket bucket = new ThrottlingBucket(20);
      for (int i = 0; i < 20; i++) {
        expect(bucket.removeDrop(), true);
      }
      expect(bucket.removeDrop(), false);
    });
  });

  group('AnalyticsImpl', () {
    test('respects disabled', () {
      AnalyticsImplMock mock = createMock();
      mock.optIn = false;
      mock.sendException('FooBar exception');
      expect(mock.optIn, false);
      expect(mock.mockPostHandler.sentValues, isEmpty);
    });

    test('hasSetOptIn', () {
      AnalyticsImplMock mock = createMock(setOptIn: false);
      expect(mock.hasSetOptIn, false);
      mock.optIn = false;
      expect(mock.hasSetOptIn, true);
    });

    test('setSessionValue', () {
      AnalyticsImplMock mock = createMock();
      mock.sendScreenView('foo');
      hasnt(mock.last, 'val');
      mock.setSessionValue('val', 'ue');
      mock.sendScreenView('bar');
      has(mock.last, 'val');
      mock.setSessionValue('val', null);
      mock.sendScreenView('baz');
      hasnt(mock.last, 'val');
    });
  });

  group('postEncode', () {
    test('simple', () {
      Map map = {'foo': 'bar', 'baz': 'qux norf'};
      expect(postEncode(map), 'foo=bar&baz=qux%20norf');
    });
  });
}
