// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * In order to use this library import the `usage_html.dart` file and
 * instantiate the [AnalyticsHtml] class.
 *
 * You'll need to provide a Google Analytics tracking ID, the application name,
 * and the application version.
 */
library usage_html;

import 'dart:html';

import 'src/usage_impl.dart';
import 'src/usage_impl_html.dart';

export 'usage.dart';

/**
 * An interface to a Google Analytics session, suitable for use in web apps.
 */
class AnalyticsHtml extends AnalyticsImpl {
  AnalyticsHtml(String trackingId, String applicationName, String applicationVersion) :
    super(
      trackingId,
      new HtmlPersistentProperties(applicationName),
      new HtmlPostHandler(),
      applicationName: applicationName,
      applicationVersion: applicationVersion) {
    int screenWidth = window.screen.width;
    int screenHeight = window.screen.height;

    setSessionValue('sr', '${screenWidth}x$screenHeight');
    setSessionValue('sd', '${window.screen.pixelDepth}-bits');
    setSessionValue('ul', window.navigator.language);
  }
}
