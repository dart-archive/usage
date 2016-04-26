// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A simple web app to hand-test the usage library.
library usage_example;

import 'dart:async';
import 'dart:html';

import 'package:usage/usage.dart';

Analytics _analytics;
String _lastUa;
int _count = 0;

void main() {
  querySelector('#foo').onClick.listen((_) => _handleFoo());
  querySelector('#bar').onClick.listen((_) => _handleBar());
  querySelector('#page').onClick.listen((_) => _changePage());
}

String _ua() => (querySelector('#ua') as InputElement).value.trim();

Future<Analytics> getAnalytics() async {
  if (_analytics == null || _lastUa != _ua()) {
    _lastUa = _ua();
    _analytics = await Analytics.create(_lastUa, 'Test app', '1.0');
    _analytics.sendScreenView(window.location.pathname);
  }

  return _analytics;
}

Future _handleFoo() async {
  Analytics analytics = await getAnalytics();
  analytics.sendEvent('main', 'foo');
}

Future _handleBar() async {
  Analytics analytics = await getAnalytics();
  analytics.sendEvent('main', 'bar');
}

Future _changePage() async {
  Analytics analytics = await getAnalytics();
  window.history.pushState(null, 'new page', '${++_count}.html');
  analytics.sendScreenView(window.location.pathname);
}
