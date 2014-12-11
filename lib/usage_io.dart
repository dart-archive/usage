// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * In order to use this library import the `usage_io.dart` file and
 * instantiate the [AnalyticsIO] class.
 *
 * You'll need to provide a Google Analytics tracking ID, the application name,
 * and the application version.
 */
library usage_io;

import 'src/usage_impl.dart';
import 'src/usage_impl_io.dart';

export 'usage.dart';

/**
 * An interface to a Google Analytics session, suitable for use in command-line
 * applications.
 */
class AnalyticsIO extends AnalyticsImpl {
  AnalyticsIO(String trackingId, String applicationName, String applicationVersion) :
    super(
      trackingId,
      new IOPersistentProperties(applicationName),
      new IOPostHandler(),
      applicationName: applicationName,
      applicationVersion: applicationVersion);
}
