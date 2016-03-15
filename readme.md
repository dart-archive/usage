# usage

`usage` is a wrapper around Google Analytics for both command-line, web, and
Flutter apps.

[![Build Status](https://travis-ci.org/dart-lang/usage.svg)](https://travis-ci.org/dart-lang/usage)
[![Coverage Status](https://img.shields.io/coveralls/dart-lang/usage.svg)](https://coveralls.io/r/dart-lang/usage?branch=master)

## Using this library

In order to use this library, call the `Analytics.create` static method.
You'll get either the command-line, web, or Flutter implementation based on
the current platform.

When you are creating a new property at [google analytics](https://www.google.com/analytics/)
make sure to select not the website option, but the **mobile app** option.

## For command-line apps

Note, for CLI apps, the usage library will send analytics pings asynchronously.
This is useful it that it doesn't block the app generally. It does have one
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
analytics.waitForLastPing(timeout: new Duration(milliseconds: 500)).then((_) {
  exit(0);
});
```

## Using the API

Import the package:

```dart
import 'package:usage/usage.dart';
```

And call some analytics code:

```dart
final String UA = ...;

Analytics ga = await Analytics.create(UA, 'ga_test', '1.0');
ga.optIn = true;

ga.sendScreenView('home');
ga.sendException('foo exception');

ga.sendScreenView('files');
ga.sendTiming('writeTime', 100);
ga.sendTiming('readTime', 20);
```

## When do we send analytics data?

We use an opt-in method for sending analytics information. There are essentially
three states for when we send information:

*Sending screen views* If the user has not opted in, the library will only send
information about screen views. This allows tools to do things like version
checks, but does not send any additional information.

*Opt-in* If the user opts-in to analytics collection the library sends all
requested analytics info. This includes screen views, events, timing
information, and exceptions.

*Opt-ing out* In order to not send analytics information, either do not call the
analytics methods, or create and use the `AnalyticsMock` class. This provides
an instance you can use in place of a real analytics object but each analytics
method is a no-op.

## Other info

For both classes, you need to provide a Google Analytics tracking ID, the
application name, and the application version.

Your application should provide an opt-in option for the user. If they opt-in,
set the `optIn` field to `true`. This setting will persist across sessions
automatically.

*Note:* This library is intended for use with the Google Analytics application /
mobile app style tracking IDs (as opposed to the web site style tracking IDs).

For more information, please see the Google Analytics Measurement Protocol
[Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).

## Issues and bugs

Please file reports on the
[GitHub Issue Tracker](https://github.com/dart-lang/usage/issues).

## License

You can view our license
[here](https://github.com/dart-lang/usage/blob/master/LICENSE).
