// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.usage_test;

import 'package:test/test.dart';
import 'package:usage/usage.dart';

main() => defineTests();

void defineTests() {
  group('AnalyticsMock', () {
    test('simple', () {
      AnalyticsMock mock = new AnalyticsMock();
      mock.sendScreenView('main');
      mock.sendEvent('files', 'save');
      mock.sendSocial('g+', 'plus', 'userid');
      mock.sendTiming('compile', 123);
      mock.startTimer('compile').finish();
      mock.sendException('FooException');
      mock.setSessionValue('val', 'ue');
      return mock.waitForLastPing();
    });
  });

  group('sanitizeStacktrace', () {
    test('replace file', () {
      expect(sanitizeStacktrace(
          '(file:///Users/foo/tmp/error.dart:3:13)',
          shorten: false),
          '(error.dart:3:13)');
    });

    test('replace files', () {
      expect(sanitizeStacktrace(
          'foo (file:///Users/foo/tmp/error.dart:3:13)\n'
          'bar (file:///Users/foo/tmp/error.dart:3:13)',
          shorten: false),
          'foo (error.dart:3:13)\nbar (error.dart:3:13)');
    });

    test('shorten 1', () {
      expect(sanitizeStacktrace(
          '(file:///Users/foo/tmp/error.dart:3:13)'),
          '(error.dart:3:13)');
    });

    test('shorten 2', () {
      expect(sanitizeStacktrace(
          'foo (file:///Users/foo/tmp/error.dart:3:13)\n'
          'bar (file:///Users/foo/tmp/error.dart:3:13)'),
          'foo (error.dart:3:13) bar (error.dart:3:13)');
    });

    test('shorten 3', () {
      expect(sanitizeStacktrace(
          'foo (package:foo/foo.dart:3:13)\n'
          'bar (dart:async/schedule_microtask.dart:41)'),
          'foo (foo/foo.dart:3:13) bar (async/schedule_microtask.dart:41)');
    });
  });
}
