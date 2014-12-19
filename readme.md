# usage

`usage` is a wrapper around Google Analytics for both command-line apps and web
apps.

[![Build Status](https://travis-ci.org/dart-lang/usage.svg)](https://travis-ci.org/dart-lang/usage)
[![Coverage Status](https://img.shields.io/coveralls/dart-lang/usage.svg)](https://coveralls.io/r/dart-lang/usage?branch=master)

## For web apps

In order to use this library as a web app, import the `usage_html.dart` library
and instantiate the `AnalyticsHtml` class.

## For command-line apps

In order to use this library as a command-line app, import the `usage_io.dart`
library and instantiate the `AnalyticsIO` class.

Note, for CLI apps, the usage library will send analytics pings asynchronously.
This is useful it that it doesn't block the app generally. It does have one
side-effect, in that outstanding asynchronous requests will block termination
of the VM until that request finishes. So, for short-lived CLI tools, pinging
Google Analytics can cause the tool to pause for several seconds before it
terminates. This is often undesired - gathering analytics information shouldn't
negatively effect the tool's UX.

One solution to this is to gather up all the `Future`'s that the send()
analytics methods return, and wait on them with a timeout. So, send analytics
pings on a best effort basis, but prefer to let the tool exit reasonably
quickly. Something like:

```
void _exitApp([Future someAnalyticsFuture]) {
  Future f = someAnalyticsFuture == null ? new Future.value() : someAnalyticsFuture;
  f.timeout(new Duration(milliseconds: 500), onTimeout: () => null).then((_) {
    io.exit(0);
  };
}
```

In the future, in order to make this easier to do for CLI clients, we may roll
some of this functionality into the library. I.e., provide something like a
`waitForLastPing(Duration timeout)` method on the CLI client.

## Using the API

Import the package (in this example we use the `dart:io` version):

    import 'package:usage/usage_io.dart';

And call some analytics code:

```
final String UA = ...;

Analytics ga = new AnalyticsIO(UA, 'ga_test', '1.0');
ga.optIn = true;

ga.sendScreenView('home');
ga.sendException('foo exception');

ga.sendScreenView('files');
ga.sendTiming('writeTime', 100);
ga.sendTiming('readTime', 20);
```

## Other info

For both classes, you need to provide a Google Analytics tracking ID, the
application name, and the application version.

Your application should provide an opt-in option for the user. If they opt-in,
set the `optIn` field to `true`. This setting will persist across sessions
automatically.

For more information, please see the Google Analytics Measurement Protocol
[Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).
