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
      var mockClient = MockHttpClient();

      var postHandler = IOPostHandler(client: mockClient);
      var args = [
        <String, String>{'utv': 'varName', 'utt': '123'},
      ];
      await postHandler.sendPost('http://www.google.com', args);
      expect(mockClient.requests.single.buffer.toString(), '''
Request to http://www.google.com with ${createUserAgent()}
utv=varName&utt=123''');
      expect(mockClient.requests.single.response.drained, isTrue);
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

  group('batching', () {
    test('Without batching sends to regular url', () async {
      final mockClient = MockHttpClient();

      final analytics = AnalyticsIO(
        '<TRACKING-ID',
        'usage-test',
        '0.0.1',
        client: mockClient,
      );
      await analytics.sendEvent('my-event', 'something');
      expect(mockClient.requests.single.buffer.toString(), '''
Request to https://www.google-analytics.com/collect with ${createUserAgent()}
ec=my-event&ea=something&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event''');
    });

    test('with batching sends to batching url', () async {
      var mockClient = MockHttpClient();

      final analytics = AnalyticsIO('<TRACKING-ID', 'usage-test', '0.0.1',
          client: mockClient);
      await analytics.withBatching(() async {
        await analytics.sendEvent('my-event1', 'something1');
        await analytics.sendEvent('my-event2', 'something2');
        await analytics.sendEvent('my-event3', 'something3');
        await analytics.sendEvent('my-event4', 'something4');
      }, maxEventsPerBatch: 3);
      await analytics.sendEvent('my-event-not-batched', 'something');

      expect(mockClient.requests.length, 3);
      expect(mockClient.requests[0].buffer.toString(), '''
Request to https://www.google-analytics.com/batch with ${createUserAgent()}
ec=my-event1&ea=something1&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event
ec=my-event2&ea=something2&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event
ec=my-event3&ea=something3&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event''');
      expect(mockClient.requests[1].buffer.toString(), '''
Request to https://www.google-analytics.com/batch with ${createUserAgent()}
ec=my-event4&ea=something4&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event''');
      expect(mockClient.requests[2].buffer.toString(), '''
Request to https://www.google-analytics.com/collect with ${createUserAgent()}
ec=my-event-not-batched&ea=something&an=usage-test&av=0.0.1&ul=en-us&v=1&tid=%3CTRACKING-ID&cid=8e3fa343-70bc-4afe-ad81-5fed4256b4e8&t=event''');
    });
  });
}

class MockHttpClient implements HttpClient {
  final List<MockHttpClientRequest> requests = <MockHttpClientRequest>[];
  @override
  String? userAgent;
  MockHttpClient();

  @override
  Future<HttpClientRequest> postUrl(Uri uri) async {
    final request = MockHttpClientRequest();
    request.buffer.writeln('Request to $uri with $userAgent');
    requests.add(request);
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  final buffer = StringBuffer();
  final MockHttpClientResponse response = MockHttpClientResponse();

  MockHttpClientRequest();

  @override
  void write(Object? o) {
    buffer.write(o);
  }

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  bool drained = false;
  MockHttpClientResponse();

  @override
  Future<E> drain<E>([E? futureValue]) async {
    drained = true;
    return futureValue as E;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}
