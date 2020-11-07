// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library usage.usage_impl_io_test;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:usage/src/usage_impl_io.dart';

void main() => defineTests();

void defineTests() {
  group('IOPostHandler', () {
    test('sendPost', () async {
      var httpClient = MockHttpClient();
      var postHandler = IOPostHandler(mockClient: httpClient);
      var args = <String, dynamic>{'utv': 'varName', 'utt': 123};
      await postHandler.sendPost('http://www.google.com', args);
      expect(httpClient.sendCount, 1);
    });
  });

  group('IOPersistentProperties', () {
    test('add', () {
      var props = IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
    });

    test('remove', () {
      var props = IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
      props['foo'] = null;
      expect(props['foo'], null);
    });
  });

  group('usage_impl_io', () {
    test('getDartVersion', () {
      expect(getDartVersion(), isNotNull);
    });

    test('getPlatformLocale', () {
      expect(getPlatformLocale(), isNotNull);
    });
  });
}

class MockHttpClient implements HttpClient {
  @override
  String? userAgent;
  int sendCount = 0;
  int writeCount = 0;
  bool closed = false;

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return Future.value(MockHttpClientRequest(this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  final MockHttpClient client;

  MockHttpClientRequest(this.client);

  @override
  void write(Object? obj) {
    client.writeCount++;
  }

  @override
  Future<HttpClientResponse> close() {
    client.closed = true;
    return Future.value(MockHttpClientResponse(client));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class MockHttpClientResponse implements HttpClientResponse {
  final MockHttpClient client;

  MockHttpClientResponse(this.client);

  @override
  Future<E> drain<E>([E? futureValue]) {
    client.sendCount++;
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
