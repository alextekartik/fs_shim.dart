// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_system_test;

import 'package:fs_shim/fs.dart';
import 'test_common.dart';
import 'package:path/path.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  group('file_system', () {
    test('equals', () {
      expect(fs, fs);
    });

    test('pathContext', () {
      // for now all are the same as current
      expect(fs.pathContext, context);
    });

    test('prepare', () async {
      Directory top = await ctx.prepare();

      List<String> parts = ctx.fs.pathContext.split(top.path);
      expect(parts, contains("prepare"));
    });
  });
}