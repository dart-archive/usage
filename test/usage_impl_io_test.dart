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
      var httpClient = new MockHttpClient();
      IOPostHandler postHandler = new IOPostHandler(mockClient: httpClient);
      Map<String, dynamic> args = {'utv': 'varName', 'utt': 123};
      await postHandler.sendPost('http://www.google.com', args);
      expect(httpClient.sendCount, 1);
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
  String userAgent;
  int sendCount = 0;
  int writeCount = 0;
  bool closed = false;

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return new Future.value(new MockHttpClientRequest(this));
  }

  @override
  noSuchMethod(Invocation invocation) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  final MockHttpClient client;

  MockHttpClientRequest(this.client);

  @override
  void write(Object obj) {
    client.writeCount++;
  }

  @override
  Future<HttpClientResponse> close() {
    client.closed = true;
    return new Future.value(new MockHttpClientResponse(client));
  }

  @override
  noSuchMethod(Invocation invocation) {}
}

class MockHttpClientResponse implements HttpClientResponse {
  final MockHttpClient client;

  MockHttpClientResponse(this.client);

  @override
  Future<E> drain<E>([E futureValue]) {
    client.sendCount++;
    return new Future.value();
  }

  @override
  noSuchMethod(Invocation invocation) {}
}
