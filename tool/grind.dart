// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.grind;

import 'dart:io';

import 'package:grinder/grinder.dart';

final Directory _buildExampleDir = Directory('build/example');

void main(List<String> args) => grind(args);

@Task()
void init() => _buildExampleDir.createSync(recursive: true);

@Task()
@Depends(init)
void build() {
  // Compile `test/web_test.dart` to the `build/test` dir; measure its size.
  var srcFile = File('example/example.dart');
  Dart2js.compile(srcFile,
      outDir: _buildExampleDir,
      minify: true,
      extraArgs: ['--conditional-directives']);
  var outFile = joinFile(_buildExampleDir, ['example.dart.js']);

  log('${outFile.path} compiled to ${_printSize(outFile)}');
}

@Task()
void clean() => delete(buildDir);

String _printSize(File file) => '${(file.lengthSync() + 1023) ~/ 1024}k';
