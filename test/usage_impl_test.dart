// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.impl_test;

import 'package:test/test.dart';
import 'package:usage/src/usage_impl.dart';

import 'src/common.dart';

main() => defineTests();

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
      mock.enabled = false;
      mock.sendException('FooBar exception');
      expect(mock.enabled, false);
      expect(mock.mockPostHandler.sentValues, isEmpty);
    });

    test('firstRun', () {
      AnalyticsImplMock mock = createMock();
      expect(mock.firstRun, true);
      mock = createMock(props: {'firstRun': false});
      expect(mock.firstRun, false);
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

    test('waitForLastPing', () {
      AnalyticsImplMock mock = createMock();
      mock.sendScreenView('foo');
      mock.sendScreenView('bar');
      mock.sendScreenView('baz');
      return mock.waitForLastPing(timeout: new Duration(milliseconds: 100));
    });
  });

  group('postEncode', () {
    test('simple', () {
      Map<String, dynamic> map = {'foo': 'bar', 'baz': 'qux norf'};
      expect(postEncode(map), 'foo=bar&baz=qux%20norf');
    });
  });
}
