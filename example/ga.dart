// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple command-line app to hand-test the usage library.
 */
library usage_ga;

import 'package:usage/usage_io.dart';

void main(List args) {
  final String DEFAULT_UA = 'UA-55029513-1';

  if (args.isEmpty) {
    print('usage: dart ga <GA tracking ID>');
    print('pinging default UA value (${DEFAULT_UA})');
  } else {
    print('pinging ${args.first}');
  }

  String ua = args.isEmpty ? DEFAULT_UA : args.first;

  Analytics ga = new AnalyticsIO(ua, 'ga_test', '1.0');
  ga.optIn = true;

  ga.sendScreenView('home').then((_) {
    return ga.sendScreenView('files');
  }).then((_) {
    return ga.sendException('foo exception, line 123:56');
  }).then((_) {
    return ga.sendTiming('writeDuration', 123);
  }).then((_) {
    return ga.sendEvent('create', 'consoleapp', label: 'Console App');
  }).then((_) {
    print('pinged ${ua}');
  });
}
