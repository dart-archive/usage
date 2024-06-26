[![pub package](https://img.shields.io/pub/v/usage.svg)](https://pub.dev/packages/usage)
[![package publisher](https://img.shields.io/pub/publisher/usage.svg)](https://pub.dev/packages/usage/publisher)

# DEPRECATED

This package is no longer maintained.
https://github.com/dart-archive/usage/issues/185 has details and
discussion, but briefly:

- this package uses the older Universal Analytics protocol to record hits to
  Google Analytics
- Universal Analytics properties will stop processing new hits on July 1, 2023
- this library does not support the newer GA4 protocol
- we (the Dart team) originally built this package for our own use, but we're no
  longer consuming it

Clients who want to record hits to Google Analytics could:

- for web clients, wrapping the gtags.js library is a good solution
- for native clients, sending hits to the new protocol is not much more
  difficult than sending HTTP POSTs to the right endpoint

See also https://github.com/dart-archive/usage/issues/185 other potential
remediations.

## For web apps

To use this library as a web app, import the `usage_html.dart` library and
instantiate the `AnalyticsHtml` class.

## For Flutter apps

Flutter applications can use the `AnalyticsIO` version of this library. They will need
to specify the documents directory in the constructor in order to tell the library where
to save the analytics preferences:

```dart
import 'package:flutter/services.dart';
import 'package:usage/usage_io.dart';

void main() {
  final String UA = ...;

  Analytics ga = new AnalyticsIO(UA, 'ga_test', '3.0',
    documentsDirectory: PathProvider.getApplicationDocumentsDirectory());
  ...
}
```

## For command-line apps

To use this library as a command-line app, import the `usage_io.dart` library
and instantiate the `AnalyticsIO` class.

Note, for CLI apps, the usage library will send analytics pings asynchronously.
This is useful in that it doesn't block the app generally. It does have one
side-effect, in that outstanding asynchronous requests will block termination
of the VM until that request finishes. So, for short-lived CLI tools, pinging
Google Analytics can cause the tool to pause for several seconds before it
terminates. This is often undesired - gathering analytics information shouldn't
negatively effect the tool's UX.

One solution to this is to use the `waitForLastPing({Duration timeout})` method
on the analytics object. This will wait until all outstanding analytics requests
have completed, or until the specified duration has elapsed. So, CLI apps can do
something like:

```dart
await analytics.waitForLastPing(timeout: new Duration(milliseconds: 200));
analytics.close();
```

or:

```dart
await analytics.waitForLastPing(timeout: new Duration(milliseconds: 200));
exit(0);
```

## Using the API

Import the package (in this example we use the `dart:io` version):

```dart
import 'package:usage/usage_io.dart';
```

And call some analytics code:

```dart
final String UA = ...;

Analytics ga = new AnalyticsIO(UA, 'ga_test', '3.0');
ga.analyticsOpt = AnalyticsOpt.optIn;

ga.sendScreenView('home');
ga.sendException('foo exception');

ga.sendScreenView('files');
ga.sendTiming('writeTime', 100);
ga.sendTiming('readTime', 20);
```

## When do we send analytics data?

You can use this library in an opt-in manner or an opt-out one. It defaults to
opt-out - data will be sent to Google Analytics unless the user explicitly
opts-out. The mode can be adjusted by changing the value of the
`Analytics.analyticsOpt` field.

*Opt-out* In opt-out mode, if the user does not explicitly opt-out of collecting
analytics, the usage library will send usage data.

*Opt-in* In opt-in mode, no data will be sent until the user explicitly opt-in
to collection. This includes screen views, events, timing information, and exceptions.

## Other info

For both classes, you need to provide a Google Analytics tracking ID, the
application name, and the application version.

*Note:* This library is intended for use with the Google Analytics application /
mobile app style tracking IDs (as opposed to the web site style tracking IDs).

For more information, please see the Google Analytics Measurement Protocol
[Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).

## Contributing

Tests can be run using `pub run test`.
