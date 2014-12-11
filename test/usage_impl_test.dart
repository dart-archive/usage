// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.impl_test;

import 'package:unittest/unittest.dart';
import 'package:usage/src/usage_impl.dart';
import 'package:usage/src/usage_impl_io.dart';

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

  group('sanitizeFilePaths', () {
    test('replace file', () {
      expect(sanitizeFilePaths(
          '(file:///Users/foo/tmp/error.dart:3:13)'),
          '(error.dart:3:13)');
    });

    test('replace files', () {
      expect(sanitizeFilePaths(
          'foo (file:///Users/foo/tmp/error.dart:3:13)\n'
          'bar (file:///Users/foo/tmp/error.dart:3:13)'),
          'foo (error.dart:3:13)\nbar (error.dart:3:13)');
    });
  });

  group('IOPersistentProperties', () {
    test('add', () {
      IOPersistentProperties props = new IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
    });

    test('remove', () {
      IOPersistentProperties props = new IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
      props['foo'] = null;
      expect(props['foo'], null);
    });
  });
}
