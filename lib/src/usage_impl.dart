// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage_impl;

import 'dart:async';
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../usage.dart';

final int _MAX_EXCEPTION_LENGTH = 100;

// Matches file:/, non-ws, /, non-ws, .dart
final RegExp _pathRegex = new RegExp(r'file:/\S+/(\S+\.dart)');

String postEncode(Map<String, String> map) {
  // &foo=bar
  return map.keys
      .map((key) => "${key}=${Uri.encodeComponent(map[key])}")
      .join('&');
}

/**
 * Santitize a string potentially containing file paths. This will remove all
 * but the last file name in order to remove any PII that may be contained in
 * the full file path. For example, this will shorten:
 *
 *     file:///Users/foobar/tmp/error.dart
 *
 * to
 *
 *     error.dart
 */
String sanitizeFilePaths(String stackTrace) {
  Iterable<Match> iter = _pathRegex.allMatches(stackTrace);
  iter = iter.toList().reversed;

  for (Match match in iter) {
    String replacement = match.group(1);
    stackTrace = stackTrace.substring(0, match.start)
        + replacement + stackTrace.substring(match.end);
  }

  return stackTrace;
}

/**
 * A throttling algorithim. This models the throttling after a bucket with
 * water dripping into it at the rate of 1 drop per second. If the bucket has
 * water when an operation is requested, 1 drop of water is removed and the
 * operation is performed. If not the operation is skipped. This algorithim
 * lets operations be peformed in bursts without throttling, but holds the
 * overall average rate of operations to 1 per second.
 */
class ThrottlingBucket {
  final int startingCount;
  int drops;
  int _lastReplenish;

  ThrottlingBucket(this.startingCount) {
    drops = startingCount;
    _lastReplenish = new DateTime.now().millisecondsSinceEpoch;
  }

  bool removeDrop() {
    _checkReplenish();

    if (drops <= 0) {
      return false;
    } {
      drops--;
      return true;
    }
  }

  void _checkReplenish() {
    int now = new DateTime.now().millisecondsSinceEpoch;

    if (_lastReplenish + 1000 >= now) {
      int inc = (now - _lastReplenish) ~/ 1000;
      drops = math.min(drops + inc, startingCount);
      _lastReplenish += (1000 * inc);
    }
  }
}

abstract class AnalyticsImpl implements Analytics {
  static const String _GA_URL = 'https://www.google-analytics.com/collect';

  /// Tracking ID / Property ID.
  final String trackingId;

  final PersistentProperties properties;
  final PostHandler postHandler;

  final ThrottlingBucket _bucket = new ThrottlingBucket(20);
  final Map<String, dynamic> _variableMap = {};

  AnalyticsImpl(this.trackingId, this.properties, this.postHandler,
      {String applicationName, String applicationVersion}) {
    assert(trackingId != null);

    if (applicationName != null) setSessionValue('an', applicationName);
    if (applicationVersion != null) setSessionValue('av', applicationVersion);
  }

  bool get optIn => properties['optIn'] == true;

  set optIn(bool value) {
    properties['optIn'] = value;
  }

  bool get hasSetOptIn => properties['optIn'] != null;

  Future sendScreenView(String viewName) {
    Map args = {'cd': viewName};
    return _sendPayload('screenview', args);
  }

  Future sendEvent(String category, String action, {String label, int value}) {
    if (!optIn) return new Future.value();

    Map args = {'ec': category, 'ea': action};
    if (label != null) args['el'] = label;
    if (value != null) args['ev'] = '${value}';
    return _sendPayload('event', args);
  }

  Future sendSocial(String network, String action, String target) {
    if (!optIn) return new Future.value();

    Map args = {'sn': network, 'sa': action, 'st': target};
    return _sendPayload('social', args);
  }

  Future sendTiming(String variableName, int time, {String category,
        String label}) {
    if (!optIn) return new Future.value();

    Map args = {'utv': variableName, 'utt': '${time}'};
    if (label != null) args['utl'] = label;
    if (category != null) args['utc'] = category;
    return _sendPayload('timing', args);
  }

  Future sendException(String description, {bool fatal}) {
    if (!optIn) return new Future.value();

    // In order to ensure that the client of this API is not sending any PII
    // data, we strip out any stack trace that may reference a path on the
    // user's drive (file:/...).
    if (description.contains('file:/')) {
      description = description.substring(0, description.indexOf('file:/'));
    }

    if (description != null && description.length > _MAX_EXCEPTION_LENGTH) {
      description = description.substring(0, _MAX_EXCEPTION_LENGTH);
    }

    Map args = {'exd': description};
    if (fatal != null && fatal) args['exf'] = '1';
    return _sendPayload('exception', args);
  }

  void setSessionValue(String param, dynamic value) {
    if (value == null) {
      _variableMap.remove(param);
    } else {
      _variableMap[param] = '${value}';
    }
  }

  /**
   * Anonymous Client ID. The value of this field should be a random UUID v4.
   */
  String get _clientId => properties['clientId'];

  void _initClientId() {
    if (_clientId == null) {
      properties['clientId'] = new Uuid().v4();
    }
  }

  // Valid values for [hitType] are: 'pageview', 'screenview', 'event',
  // 'transaction', 'item', 'social', 'exception', and 'timing'.
  Future _sendPayload(String hitType, Map args) {
    if (_bucket.removeDrop()) {
      _initClientId();

      _variableMap.forEach((key, value) {
        args[key] = value;
      });

      args['v'] = '1'; // protocol version
      args['tid'] = trackingId;
      args['cid'] = _clientId;
      args['t'] = hitType;

      return postHandler.sendPost(_GA_URL, args);
    } else {
      return new Future.value();
    }
  }
}

/**
 * A persistent key/value store. An [AnalyticsImpl] instance expects to have one
 * of these injected into it. There are default implementations for `dart:io`
 * and `dart:html` clients.
 *
 * The [name] paramater is used to uniquely store these properties on disk /
 * persistent storage.
 */
abstract class PersistentProperties {
  final String name;

  PersistentProperties(this.name);

  dynamic operator[](String key);
  void operator[]=(String key, dynamic value);
}

/**
 * A utility class to perform HTTP POSTs. An [AnalyticsImpl] instance expects to
 * have one of these injected into it. There are default implementations for
 * `dart:io` and `dart:html` clients.
 */
abstract class PostHandler {
  Future sendPost(String url, Map<String, String> parameters);
}
