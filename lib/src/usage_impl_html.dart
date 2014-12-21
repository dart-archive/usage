// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage_impl_html;

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';

import 'usage_impl.dart';

class HtmlPostHandler extends PostHandler {
  final Function mockRequestor;

  HtmlPostHandler({Function this.mockRequestor});

  Future sendPost(String url, Map<String, String> parameters) {
    int viewportWidth = document.documentElement.clientWidth;
    int viewportHeight = document.documentElement.clientHeight;

    parameters['vp'] = '${viewportWidth}x$viewportHeight';

    String data = postEncode(parameters);
    var request = mockRequestor == null ? HttpRequest.request : mockRequestor;
    return request(url, method: 'POST', sendData: data).catchError((e) {
      // Catch errors that can happen during a request, but that we can't do
      // anything about, e.g. a missing internet conenction.
    });
  }
}

class HtmlPersistentProperties extends PersistentProperties {
  Map _map;

  HtmlPersistentProperties(String name) : super(name) {
    String str = window.localStorage[name];
    if (str == null || str.isEmpty) str = '{}';
    _map = JSON.decode(str);
  }

  dynamic operator[](String key) => _map[key];

  void operator[]=(String key, dynamic value) {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    window.localStorage[name] = JSON.encode(_map);
  }
}
