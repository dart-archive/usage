// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.usage_test;

import 'package:unittest/unittest.dart';
import 'package:usage/usage.dart';

void defineTests() {
  group('AnalyticsMock', () {
    test('simple', () {
      AnalyticsMock mock = new AnalyticsMock();
      mock.sendScreenView('main');
      mock.sendEvent('files', 'save');
      mock.sendSocial('g+', 'plus', 'userid');
      mock.sendTiming('compile', 123);
      mock.sendException('FooException');
      mock.setSessionValue('val', 'ue');
    });
  });
}
