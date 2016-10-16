// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:flutter/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../usage.dart';
import 'usage_impl.dart';
import 'usage_impl_io.dart';

Future<Analytics> createAnalytics(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String analyticsUrl
}) async {
    Directory dataDirectory = await PathProvider.getTemporaryDirectory();

    String fileName = '.${applicationName.replaceAll(' ', '_')}';
    File file = new File(path.join(dataDirectory.path, fileName));
    await file.create();
    String contents = await file.readAsString();
    if (contents.isEmpty) contents = '{}';
    Map map = JSON.decode(contents);

    return new AnalyticsImpl(
      trackingId,
      new FlutterPersistentProperties(applicationName, file, map),
      new FlutterPostHandler(),
      applicationName: applicationName,
      applicationVersion: applicationVersion,
      analyticsUrl: analyticsUrl
    );
}

String _createUserAgent() {
  final String locale = getPlatformLocale() ?? '';

  if (Platform.isAndroid) {
    return 'Mozilla/5.0 (Android; Mobile; ${locale})';
  } else if (Platform.isIOS) {
    return 'Mozilla/5.0 (iPhone; U; CPU iPhone OS like Mac OS X; ${locale})';
  } else {
    // Dart/1.8.0 (macos; macos; macos; en_US)
    final String os = Platform.operatingSystem;
    return "Dart/${getDartVersion()} (${os}; ${os}; ${os}; ${locale})";
  }
}

class FlutterPostHandler extends PostHandler {
  final String _userAgent;
  final HttpClient mockClient;

  FlutterPostHandler({HttpClient this.mockClient}) : _userAgent = _createUserAgent();

  Future sendPost(String url, Map<String, dynamic> parameters) {
    String data = postEncode(parameters);

    Map<String, String> headers = <String, String>{ 'User-Agent': _userAgent };

    return http.post(url, body: data, headers: headers);
  }
}

class FlutterPersistentProperties extends PersistentProperties {
  File _file;
  Map _map;

  FlutterPersistentProperties(String name, this._file, this._map) : super(name);

  dynamic operator[](String key) => _map[key];

  void operator[]=(String key, dynamic value) {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    _file.writeAsString(JSON.encode(_map) + '\n');
  }
}
