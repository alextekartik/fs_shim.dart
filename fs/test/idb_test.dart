import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';

import 'test_common.dart';

void main() {
  group('idb_test', () {
    group('Node', () {
      test('fromMap/toMap', () {
        var dateTextCompat = '2022-12-20T00:00:00.000';
        var node = Node.fromMap(null,
            {'name': '/', 'type': 'DIRECTORY', 'modified': dateTextCompat}, 1);
        expect(node.type, FileSystemEntityType.directory);
        expect(node.modified, DateTime.tryParse(dateTextCompat));
        expect(node.toMap(), {
          'name': '/',
          'type': 'dir',
          'v': 2,
          'pn': '/',
          'modified': node.modified!.toUtc().toIso8601String()
        });

        node = Node.fromMap(null, {'name': '/', 'type': 'dir'}, 1);
        expect(node.type, FileSystemEntityType.notFound);
        node = Node.fromMap(null, {'name': '/', 'type': 'dir', 'v': 2}, 1);
        expect(node.type, FileSystemEntityType.directory);
        expect(node.toMap(), {'name': '/', 'type': 'dir', 'v': 2, 'pn': '/'});

        var modified = DateTime(2022, 12, 20);
        node = Node(null, '/', FileSystemEntityType.directory, modified, null);
        expect(node.toMap(), {
          'name': '/',
          'type': 'dir',
          'v': 2,
          'pn': '/',
          'modified': modified.toUtc().toIso8601String()
        });
      });
    });
    test('typeFromString', () {
      expect(typeFromString('dir'), FileSystemEntityType.directory);
      expect(typeFromString('file'), FileSystemEntityType.file);
      expect(typeFromString('link'), FileSystemEntityType.link);
      expect(typeFromString('dummy'), FileSystemEntityType.notFound);
    });
    test('typeFromStringCompat', () {
      expect(typeFromStringCompat('DIRECTORY'), FileSystemEntityType.directory);
      expect(typeFromStringCompat('FILE'), FileSystemEntityType.file);
      expect(typeFromStringCompat('LINK'), FileSystemEntityType.link);
      expect(typeFromStringCompat(FileSystemEntityType.directory.toString()),
          FileSystemEntityType.directory);
      expect(typeFromStringCompat(FileSystemEntityType.file.toString()),
          FileSystemEntityType.file);
      expect(typeFromStringCompat(FileSystemEntityType.link.toString()),
          FileSystemEntityType.link);
      expect(typeFromStringCompat('dummy'), FileSystemEntityType.notFound);
    });
  });
}
