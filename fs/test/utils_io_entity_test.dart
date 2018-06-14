@TestOn("vm")
library fs_shim.test.utils_entity_tests;

import 'package:fs_shim/utils/io/entity.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:dev_test/test.dart';

import 'test_common_io.dart' show ioFileSystemTestContext;

String get outPath => ioFileSystemTestContext.outPath;

main() {
  group('entity', () {
    test('as', () async {
      Link fileSystemEntity = new Link(join(outPath, 'fse'));
      Link link = asLink(fileSystemEntity);
      File file = asFile(fileSystemEntity);
      Directory directory = asDirectory(fileSystemEntity);
      expect(link.path, fileSystemEntity.path);
      expect(file.path, fileSystemEntity.path);
      expect(directory.path, fileSystemEntity.path);
    });

    test('child', () async {
      Directory top = new Directory(join(outPath, 'top'));
      Link link = childLink(top, "child");
      File file = childFile(top, "child");
      Directory directory = childDirectory(top, "child");
      expect(basename(link.path), "child");
      expect(basename(file.path), "child");
      expect(basename(directory.path), "child");
      expect(link.parent.path, top.path);
      expect(file.parent.path, top.path);
      expect(directory.parent.path, top.path);
    });
  });
}