library fs_shim.src.io.io_file_stat;

import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as io;
import 'dart:io' as vm_io show FileStat;

// FileStat Wrap/unwrap
FileStatNode wrapIoFileStat(vm_io.FileStat ioFileStat) =>
    ioFileStat != null ? new FileStatNode.io(ioFileStat) : null;
vm_io.FileStat unwrapIoFileStat(FileStat fileStat) =>
    fileStat != null ? (fileStat as FileStatNode).ioFileStat : null;

class FileStatNotFound extends FileStatNode {
  FileStatNotFound() : super.io(null);
  @override
  int get size => null;

  @override
  DateTime get modified => null;

  @override
  FileSystemEntityType get type => FileSystemEntityType.notFound;

  @override
  String toString() => "FileStat($type)";
}

class FileStatNode implements FileStat {
  FileStatNode.io(this.ioFileStat);

  vm_io.FileStat ioFileStat;

  @override
  DateTime get modified => ioFileStat.modified;

  @override
  int get size => ioFileStat.size;

  @override
  FileSystemEntityType get type =>
      wrapIoFileSystemEntityTypeImpl(ioFileStat.type);

  @override
  String toString() => ioFileStat.toString();
}

Future<FileStatNode> pathFileStat(String path) async {
  try {
    // var stat = await ioWrap(nativeInstance.stat());
    var stat = await ioWrap(io.FileStat.stat(path));
    return new FileStatNode.io(stat);
  } catch (e) {
    return new FileStatNotFound();
  }
}