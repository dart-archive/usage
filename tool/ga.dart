// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple command-line app to hand-test the usage library.
 */
library usage_ga;

import 'package:usage/usage_io.dart';

void main() {
  final String UA = 'UA-55029513-1';

  Analytics ga = new AnalyticsIO(UA, 'ga_test', '1.0');
  ga.optIn = true;

  ga.sendScreenView('home').then((_) {
    return ga.sendScreenView('files');
  }).then((_) {
    return ga.sendException('foo exception, line 123:56');
  }).then((_) {
    return ga.sendEvent('create', 'consoleapp', label: 'Console App');
  }).then((_) {
    print('pinged ${UA}.');
  });
}
