@TestOn("vm")
// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library tekartik_fs_test.fs_io_test;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_fs_test/fs_current_dir_file_test.dart' as current_dir;
import 'test_common_io.dart';

main() {
  group('io', () {
    current_dir.defineTests(fileSystemIo);
    defineTests(fileSystemTestContextIo);
  });
}
