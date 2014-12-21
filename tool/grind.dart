// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.grind;

import 'dart:io';

import 'package:grinder/grinder.dart';

final Directory BUILD_DIR = new Directory('build');
final Directory BUILD_TEST_DIR = new Directory('build/test');

void main(List<String> args) {
  task('init', init);
  task('build', build, ['init']);
  task('clean', clean);

  startGrinder(args);
}

/// Do any necessary build set up.
void init(GrinderContext context) {
  // Verify we're running in the project root.
  if (!getDir('lib').existsSync() || !getFile('pubspec.yaml').existsSync()) {
    context.fail('This script must be run from the project root.');
  }

  BUILD_TEST_DIR.createSync(recursive: true);
}

void build(GrinderContext context) {
  // Compile `test/web_test.dart` to the `build/test` dir; measure its size.
  File srcFile = new File('test/web_test.dart');
  Dart2js.compile(context, srcFile, outDir: BUILD_TEST_DIR, minify: true);
  File outFile = joinFile(BUILD_TEST_DIR, ['web_test.dart.js']);

  context.log('${outFile.path} compiled to ${_printSize(outFile)}');
}

/// Delete all generated artifacts.
void clean(GrinderContext context) {
  // Delete the build/ dir.
  deleteEntity(BUILD_DIR, context);
}

String _printSize(File file) {
  int size = file.lengthSync();
  return '${(size + 1023) ~/ 1024}k';
}
