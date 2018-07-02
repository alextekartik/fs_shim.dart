import 'dart:async';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_node/src/directory_node.dart';
import 'package:tekartik_fs_node/src/file_node.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'import_common_node.dart' as io;
import 'package:tekartik_fs_node/src/fs_node.dart';

class FileSystemNode extends Object with FileSystemMixin implements FileSystem {
  @override
  Future<FileSystemEntityType> type(String path,
      {bool followLinks: true}) async {
    var fileStat = await io.FileStat.stat(path);
    return wrapIoFileSystemEntityTypeImpl(fileStat.type);
  }

  @override
  File newFile(String path) => file(path);

  @override
  Directory newDirectory(String path) => directory(path);

  @override
  Link newLink(String path) => link(path);

  @override
  File file(String path) => new FileNode(path);

  @override
  Directory directory(String path) => new DirectoryNode(path);

  @override
  Link link(String path) => throw 'link not implemented';

  @override
  String get name => 'io';

  @override
  bool get supportsLink => false;

  @override
  bool get supportsFileLink => false;

  @override
  String toString() => name;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(o) {
    return o is FileSystemNode;
  }

  @override
  Context get pathContext => path;

  @override
  Context get path => context;

  Future deleteAny(String path) async {
    var type = await this.type(path);
    if (type == FileSystemEntityType.directory) {
      List<FileSystemEntityNode> entities =
          await new DirectoryNode(path).list().toList();
      for (var entity in entities) {
        /*
        if (entity is DirectoryNode) {
          await deleteAnyentity.delete(recursive: recursive);
        } else if (entity is FileNode) {
          await entity.delete();
        } else {
          // TODO handle link
          print("entity unsupported ${entity} ${entity.runtimeType}");
          // throw new UnsupportedError(
          //    'entity ${entity} type ${entity.runtimeType} not supported');

        }*/
        await deleteAny(entity.path);
      }
      await new DirectoryNode(path).delete();
    } else if (type == FileSystemEntityType.file) {
      await new FileNode(path).delete();
    }
  }
}