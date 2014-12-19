// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage_impl_io;

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'usage_impl.dart';

String _createUserAgent() {
  // Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en)
  // Dart/1.8.0-edge.41170 (macos; macos; macos; null)
  String os = Platform.operatingSystem;
  String locale = Platform.environment['LANG'];
  return "Dart/${_dartVersion()} (${os}; ${os}; ${os}; ${locale})";
}

String _userHomeDir() {
  String envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  String value = Platform.environment[envKey];
  return value == null ? '.' : value;
}

String _dartVersion() {
  String ver = Platform.version;
  int index = ver.indexOf(' ');
  if (index != -1) ver = ver.substring(0, index);
  return ver;
}

class IOPostHandler extends PostHandler {
  final String _userAgent;
  final HttpClient mockClient;

  IOPostHandler({HttpClient this.mockClient}) : _userAgent = _createUserAgent();

  Future sendPost(String url, Map<String, String> parameters) {
    // Add custom parameters for OS and the Dart version.
    parameters['cd1'] = Platform.operatingSystem;
    parameters['cd2'] = 'dart ${_dartVersion()}';

    String data = postEncode(parameters);

    HttpClient client = mockClient != null ? mockClient : new HttpClient();
    client.userAgent = _userAgent;
    return client.postUrl(Uri.parse(url)).then((HttpClientRequest req) {
      req.write(data);
      return req.close();
    }).then((HttpClientResponse response) {
      response.drain();
    }).catchError((e) {
      // Catch errors that can happen during a request, but that we can't do
      // anything about, e.g. a missing internet conenction.
    });
  }
}

class IOPersistentProperties extends PersistentProperties {
  File _file;
  Map _map;

  IOPersistentProperties(String name) : super(name) {
    String fileName = '.${name.replaceAll(' ', '_')}';
    _file = new File(path.join(_userHomeDir(), fileName));
    _file.createSync();
    String contents = _file.readAsStringSync();
    if (contents.isEmpty) contents = '{}';
    _map = JSON.decode(contents);
  }

  dynamic operator[](String key) => _map[key];

  void operator[]=(String key, dynamic value) {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    _file.writeAsStringSync(JSON.encode(_map) + '\n');
  }
}
