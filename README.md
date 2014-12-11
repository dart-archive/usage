# usage

`usage` is a wrapper around Google Analytics for both command-line apps and web
apps.

In order to use this library as a web app, import the `usage_html.dart` library
and instantiate the [AnalyticsHtml] class.

In order to use this library as a command-line app, import the `usage_io.dart`
library and instantiate the [AnalyticsIO] class.

For both classes, you need to provide a Google Analytics tracking ID, the
application name, and the application version.

Your application should provide an opt-in option for the user. If they opt-in,
set the [optIn] field to `true`. This setting will persist across sessions
automatically.

For more information, please see the Google Analytics Measurement Protocol
[Policy](https://developers.google.com/analytics/devguides/collection/protocol/policy).
