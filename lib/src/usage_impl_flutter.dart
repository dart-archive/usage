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

Future<Analytics> createAnalytics(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String analyticsUrl
}) async {
    String dataPath = await getFilesDir();

    String fileName = '.${applicationName.replaceAll(' ', '_')}';
    File file = new File(path.join(dataPath, fileName));
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
  // Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en)
  // Dart/1.8.0-edge.41170 (macos; macos; macos; null)
  String os = Platform.operatingSystem;
  String locale = Platform.environment['LANG'];
  return "Dart/${_dartVersion()} (${os}; ${os}; ${os}; ${locale})";
}

String _dartVersion() {
  String ver = Platform.version;
  int index = ver.indexOf(' ');
  if (index != -1) ver = ver.substring(0, index);
  return ver;
}

class FlutterPostHandler extends PostHandler {
  final String _userAgent;
  final HttpClient mockClient;

  FlutterPostHandler({HttpClient this.mockClient}) : _userAgent = _createUserAgent();

  Future sendPost(String url, Map<String, dynamic> parameters) {
    // Add custom parameters for OS and the Dart version.
    parameters['cd1'] = Platform.operatingSystem;
    parameters['cd2'] = 'dart ${_dartVersion()}';

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
