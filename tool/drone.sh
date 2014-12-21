#!/bin/bash

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Display installed versions.
dart --version

# Get our packages.
pub get

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/usage.dart \
  lib/usage_html.dart \
  lib/usage_io.dart \
  test/all.dart

# Run the tests.
dart test/all.dart

# Measure the size of the compiled JS, for the dart:html version of the library.
dart tool/grind.dart build
