// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * `usage` is a wrapper around Google Analytics for both command-line apps
 * and web apps.
 *
 * In order to use this library as a web app, import the `analytics_html.dart`
 * library and instantiate the [AnalyticsHtml] class.
 *
 * In order to use this library as a command-line app, import the
 * `analytics_io.dart` library and instantiate the [AnalyticsIO] class.
 *
 * For both classes, you need to provide a Google Analytics tracking ID, the
 * application name, and the application version.
 *
 * Your application should provide an opt-in option for the user. If they
 * opt-in, set the [optIn] field to `true`. This setting will persist across
 * sessions automatically.
 *
 * For more information, please see the Google Analytics Measurement Protocol
 * [Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).
 */
library usage;

import 'dart:async';

// Matches file:/, non-ws, /, non-ws, .dart
final RegExp _pathRegex = new RegExp(r'file:/\S+/(\S+\.dart)');

/**
 * An interface to a Google Analytics session. [AnalyticsHtml] and [AnalyticsIO]
 * are concrete implementations of this interface. [AnalyticsMock] can be used
 * for testing or for some varients of an opt-in workflow.
 *
 * The analytics information is sent on a best-effort basis. So, failures to
 * send the GA information will not result in errors from the asynchronous
 * `send` methods.
 */
abstract class Analytics {
  /**
   * Tracking ID / Property ID.
   */
  String get trackingId;

  /**
   * Whether the user has opt-ed in to additional analytics.
   */
  bool optIn;

  /**
   * Whether the [optIn] value has been explicitly set (either `true` or
   * `false`).
   */
  bool get hasSetOptIn;

  /**
   * Sends a screen view hit to Google Analytics.
   */
  Future sendScreenView(String viewName);

  /**
   * Sends an Event hit to Google Analytics. [label] specifies the event label.
   * [value] specifies the event value. Values must be non-negative.
   */
  Future sendEvent(String category, String action, {String label, int value});

  /**
   * Sends a Social hit to Google Analytics. [network] specifies the social
   * network, for example Facebook or Google Plus. [action] specifies the social
   * interaction action. For example on Google Plus when a user clicks the +1
   * button, the social action is 'plus'. [target] specifies the target of a
   * social interaction. This value is typically a URL but can be any text.
   */
  Future sendSocial(String network, String action, String target);

  /**
   * Sends a Timing hit to Google Analytics. [variableName] specifies the
   * variable name of the timing. [time] specifies the user timing value (in
   * milliseconds). [category] specifies the category of the timing. [label]
   * specifies the label of the timing.
   */
  Future sendTiming(String variableName, int time, {String category,
      String label});

  /**
   * Start a timer. The time won't be calculated, and the analytics information
   * sent, until the [AnalyticsTimer.finish] method is called.
   */
  AnalyticsTimer startTimer(String variableName,
      {String category, String label});

  /**
   * In order to avoid sending any personally identifying information, the
   * [description] field must not contain the exception message. In addition,
   * only the first 100 chars of the description will be sent.
   */
  Future sendException(String description, {bool fatal});

  /**
   * Sets a session variable value. The value is persistent for the life of the
   * [Analytics] instance. This variable will be sent in with every analytics
   * hit. A list of valid variable names can be found here:
   * https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters.
   */
  void setSessionValue(String param, dynamic value);

  /**
   * Wait for all of the outstanding analytics pings to complete. The returned
   * `Future` will always complete without errors. You can pass in an optional
   * `Duration` to specify to only wait for a certain amount of time.
   *
   * This method is particularly useful for command-line clients. Outstanding
   * I/O requests will cause the VM to delay terminating the process. Generally,
   * users won't want their CLI app to pause at the end of the process waiting
   * for Google analytics requests to complete. This method allows CLI apps to
   * delay for a short time waiting for GA requests to complete, and then do
   * something like call `exit()` explicitly themselves.
   */
  Future waitForLastPing({Duration timeout});
}

/**
 * An object, returned by [Analytics.startTimer], that is used to measure an
 * asynchronous process.
 */
class AnalyticsTimer {
  final Analytics analytics;
  final String variableName;
  final String category;
  final String label;

  int _startMillis;
  int _endMillis;

  AnalyticsTimer(this.analytics, this.variableName,
      {this.category, this.label}) {
    _startMillis = new DateTime.now().millisecondsSinceEpoch;
  }

  int get currentElapsedMillis {
    if (_endMillis == null) {
      return new DateTime.now().millisecondsSinceEpoch - _startMillis;
    } else {
      return _endMillis - _startMillis;
    }
  }

  /**
   * Finish the timer, calculate the elapsed time, and send the information to
   * analytics. Once this is called, any future invocations are no-ops.
   */
  Future finish() {
    if (_endMillis != null) return new Future.value();

    _endMillis = new DateTime.now().millisecondsSinceEpoch;
    return analytics.sendTiming(
        variableName, currentElapsedMillis, category: category, label: label);
  }
}

/**
 * A no-op implementation of the [Analytics] class. This can be used as a
 * stand-in for that will never ping the GA server, or as a mock in test code.
 */
class AnalyticsMock implements Analytics {
  String get trackingId => 'UA-0';
  final bool logCalls;

  bool optIn = false;
  bool hasSetOptIn = true;

  /**
   * Create a new [AnalyticsMock]. If [logCalls] is true, all calls will be
   * logged to stdout.
   */
  AnalyticsMock([this.logCalls = false]);

  Future sendScreenView(String viewName) =>
      _log('screenView', {'viewName': viewName});

  Future sendEvent(String category, String action, {String label, int value}) {
    return _log('event', {'category': category, 'action': action,
      'label': label, 'value': value});
  }

  Future sendSocial(String network, String action, String target) =>
      _log('social', {'network': network, 'action': action, 'target': target});

  Future sendTiming(String variableName, int time, {String category,
      String label}) {
    return _log('timing', {'variableName': variableName, 'time': time,
      'category': category, 'label': label});
  }

  AnalyticsTimer startTimer(String variableName,
      {String category, String label}) {
    return new AnalyticsTimer(this,
        variableName, category: category, label: label);
  }

  Future sendException(String description, {bool fatal}) =>
      _log('exception', {'description': description, 'fatal': fatal});

  void setSessionValue(String param, dynamic value) { }

  Future waitForLastPing({Duration timeout}) => new Future.value();

  Future _log(String hitType, Map m) {
    if (logCalls) {
      print('analytics: ${hitType} ${m}');
    }

    return new Future.value();
  }
}

/**
 * Sanitize a stacktrace. This will shorten file paths in order to remove any
 * PII that may be contained in the full file path. For example, this will
 * shorten `file:///Users/foobar/tmp/error.dart` to `error.dart`.
 *
 * If [shorten] is `true`, this method will also attempt to compress the text
 * of the stacktrace. GA has a 100 char limit on the text that can be sent for
 * an exception. This will try and make those first 100 chars contain
 * information useful to debugging the issue.
 */
String sanitizeStacktrace(dynamic st, {bool shorten: true}) {
  String str = '${st}';

  Iterable<Match> iter = _pathRegex.allMatches(str);
  iter = iter.toList().reversed;

  for (Match match in iter) {
    String replacement = match.group(1);
    str = str.substring(0, match.start)
        + replacement + str.substring(match.end);
  }

  if (shorten) {
    // Shorten the stacktrace up a bit.
    str = str
        .replaceAll('(package:', '(')
        .replaceAll('(dart:', '(')
        .replaceAll(new RegExp(r'\s+'), ' ');
  }

  return str;
}
