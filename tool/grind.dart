// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.grind;

import 'dart:io';

import 'package:grinder/grinder.dart';

final Directory _buildExampleDir = new Directory('build/example');

main(List<String> args) => grind(args);

@Task('Do any necessary build set up')
void init() {
  // Verify we're running in the project root.
  if (!getDir('lib').existsSync() || !getFile('pubspec.yaml').existsSync()) {
    context.fail('This script must be run from the project root.');
  }

  _buildExampleDir.createSync(recursive: true);
}

@Task()
@Depends(init)
void build() {
  // Compile `test/web_test.dart` to the `build/test` dir; measure its size.
  File srcFile = new File('example/example.dart');
  Dart2js.compile(srcFile, outDir: _buildExampleDir, minify: true);
  File outFile = joinFile(_buildExampleDir, ['example.dart.js']);

  context.log('${outFile.path} compiled to ${_printSize(outFile)}');
}

@Task('Delete all generated artifacts')
void clean() {
  // Delete the build/ dir.
  delete(buildDir);
}

String _printSize(File file) => '${(file.lengthSync() + 1023) ~/ 1024}k';
