// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import '../usage.dart';
import '../uuid/uuid.dart';

String postEncode(Map<String, dynamic> map) {
  // &foo=bar
  return map.keys.map((key) {
    var value = '${map[key]}';
    return '${key}=${Uri.encodeComponent(value)}';
  }).join('&');
}

/// A throttling algorithm. This models the throttling after a bucket with
/// water dripping into it at the rate of 1 drop per second. If the bucket has
/// water when an operation is requested, 1 drop of water is removed and the
/// operation is performed. If not the operation is skipped. This algorithm
/// lets operations be performed in bursts without throttling, but holds the
/// overall average rate of operations to 1 per second.
class ThrottlingBucket {
  final int startingCount;
  int drops;
  late int _lastReplenish;

  ThrottlingBucket(this.startingCount) : drops = startingCount {
    _lastReplenish = DateTime.now().millisecondsSinceEpoch;
  }

  bool removeDrop() {
    _checkReplenish();

    if (drops <= 0) {
      return false;
    } else {
      drops--;
      return true;
    }
  }

  void _checkReplenish() {
    var now = DateTime.now().millisecondsSinceEpoch;

    if (_lastReplenish + 1000 >= now) {
      var inc = (now - _lastReplenish) ~/ 1000;
      drops = math.min(drops + inc, startingCount);
      _lastReplenish += (1000 * inc);
    }
  }
}

class AnalyticsImpl implements Analytics {
  static const String _defaultAnalyticsUrl =
      'https://www.google-analytics.com/collect';

  @override
  final String trackingId;
  @override
  final String? applicationName;
  @override
  final String? applicationVersion;

  final PersistentProperties properties;
  final PostHandler postHandler;

  final ThrottlingBucket _bucket = ThrottlingBucket(20);
  final Map<String, dynamic> _variableMap = {};

  final List<Future> _futures = [];

  @override
  AnalyticsOpt analyticsOpt = AnalyticsOpt.optOut;

  late final String _url;

  final StreamController<Map<String, dynamic>> _sendController =
      StreamController.broadcast(sync: true);

  AnalyticsImpl(this.trackingId, this.properties, this.postHandler,
      {this.applicationName, this.applicationVersion, String? analyticsUrl}) {
    if (applicationName != null) setSessionValue('an', applicationName);
    if (applicationVersion != null) setSessionValue('av', applicationVersion);

    _url = analyticsUrl ?? _defaultAnalyticsUrl;
  }

  bool? _firstRun;

  @override
  bool get firstRun {
    if (_firstRun == null) {
      _firstRun = properties['firstRun'] == null;

      if (properties['firstRun'] != false) {
        properties['firstRun'] = false;
      }
    }

    return _firstRun!;
  }

  @override
  bool get enabled {
    var optIn = analyticsOpt == AnalyticsOpt.optIn;
    return optIn
        ? properties['enabled'] == true
        : properties['enabled'] != false;
  }

  @override
  set enabled(bool value) {
    properties['enabled'] = value;
  }

  @override
  Future sendScreenView(String viewName, {Map<String, String>? parameters}) {
    var args = <String, dynamic>{'cd': viewName};
    if (parameters != null) {
      args.addAll(parameters);
    }
    return _sendPayload('screenview', args);
  }

  @override
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) {
    var args = <String, dynamic>{'ec': category, 'ea': action};
    if (label != null) args['el'] = label;
    if (value != null) args['ev'] = value;
    if (parameters != null) {
      args.addAll(parameters);
    }
    return _sendPayload('event', args);
  }

  @override
  Future sendSocial(String network, String action, String target) {
    var args = <String, dynamic>{'sn': network, 'sa': action, 'st': target};
    return _sendPayload('social', args);
  }

  @override
  Future sendTiming(String variableName, int time,
      {String? category, String? label}) {
    var args = <String, dynamic>{'utv': variableName, 'utt': time};
    if (label != null) args['utl'] = label;
    if (category != null) args['utc'] = category;
    return _sendPayload('timing', args);
  }

  @override
  AnalyticsTimer startTimer(String variableName,
      {String? category, String? label}) {
    return AnalyticsTimer(this, variableName, category: category, label: label);
  }

  @override
  Future sendException(String description, {bool? fatal}) {
    // We trim exceptions to a max length; google analytics will apply it's own
    // truncation, likely around 150 chars or so.
    const maxExceptionLength = 1000;

    // In order to ensure that the client of this API is not sending any PII
    // data, we strip out any stack trace that may reference a path on the
    // user's drive (file:/...).
    if (description.contains('file:/')) {
      description = description.substring(0, description.indexOf('file:/'));
    }

    description = description.replaceAll('\n', '; ');

    if (description.length > maxExceptionLength) {
      description = description.substring(0, maxExceptionLength);
    }

    var args = <String, dynamic>{'exd': description};
    if (fatal != null && fatal) args['exf'] = '1';
    return _sendPayload('exception', args);
  }

  @override
  dynamic getSessionValue(String param) => _variableMap[param];

  @override
  void setSessionValue(String param, dynamic value) {
    if (value == null) {
      _variableMap.remove(param);
    } else {
      _variableMap[param] = value;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onSend => _sendController.stream;

  @override
  Future waitForLastPing({Duration? timeout}) {
    Future f = Future.wait(_futures).catchError((e) => null);

    if (timeout != null) {
      f = f.timeout(timeout, onTimeout: () => null);
    }

    return f;
  }

  @override
  void close() => postHandler.close();

  @override
  String get clientId => properties['clientId'] ??= Uuid().generateV4();

  /// Send raw data to analytics. Callers should generally use one of the typed
  /// methods (`sendScreenView`, `sendEvent`, ...).
  ///
  /// Valid values for [hitType] are: 'pageview', 'screenview', 'event',
  /// 'transaction', 'item', 'social', 'exception', and 'timing'.
  Future sendRaw(String hitType, Map<String, dynamic> args) {
    return _sendPayload(hitType, args);
  }

  /// Valid values for [hitType] are: 'pageview', 'screenview', 'event',
  /// 'transaction', 'item', 'social', 'exception', and 'timing'.
  Future _sendPayload(String hitType, Map<String, dynamic> args) {
    if (!enabled) return Future.value();

    if (_bucket.removeDrop()) {
      _variableMap.forEach((key, value) {
        args[key] = value;
      });

      args['v'] = '1'; // protocol version
      args['tid'] = trackingId;
      args['cid'] = clientId;
      args['t'] = hitType;

      _sendController.add(args);

      return _recordFuture(postHandler.sendPost(_url, args));
    } else {
      return Future.value();
    }
  }

  Future _recordFuture(Future f) {
    _futures.add(f);
    return f.whenComplete(() => _futures.remove(f));
  }
}

/// A persistent key/value store. An [AnalyticsImpl] instance expects to have
/// one of these injected into it.
///
/// There are default implementations for `dart:io` and `dart:html` clients.
///
/// The [name] parameter is used to uniquely store these properties on disk /
/// persistent storage.
abstract class PersistentProperties {
  final String name;

  PersistentProperties(this.name);

  dynamic operator [](String key);

  void operator []=(String key, dynamic value);

  /// Re-read settings from the backing store. This may be a no-op on some
  /// platforms.
  void syncSettings();
}

/// A utility class to perform HTTP POSTs.
///
/// An [AnalyticsImpl] instance expects to have one of these injected into it.
/// There are default implementations for `dart:io` and `dart:html` clients.
///
/// The POST information should be sent on a best-effort basis.
///
/// The `Future` from [sendPost] should complete when the operation is finished,
/// but failures to send the information should be silent.
abstract class PostHandler {
  Future sendPost(String url, Map<String, dynamic> parameters);

  /// Free any used resources.
  void close();
}
