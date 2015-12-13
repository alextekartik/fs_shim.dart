library fs_shim.src.io.io_directory;

export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import 'io_file_system_entity.dart';
import '../../fs_io.dart';
import 'io_file.dart';

class DirectoryImpl extends FileSystemEntityImpl implements Directory {
  io.Directory get ioDir => ioFileSystemEntity;

  DirectoryImpl.io(io.Directory dir) {
    ioFileSystemEntity = dir;
  }
  DirectoryImpl(String path) {
    ioFileSystemEntity = new io.Directory(path);
  }

  //DirectoryImpl _me(_) => this;
  DirectoryImpl _ioThen(io.Directory resultIoDir) {
    if (resultIoDir == null) {
      return null;
    }
    if (resultIoDir.path == ioDir.path) {
      return this;
    }
    return new DirectoryImpl.io(resultIoDir);
  }

  @override
  Future<DirectoryImpl> create({bool recursive: false}) //
      =>
      ioWrap(ioDir.create(recursive: recursive)).then(_ioThen);

  @override
  Future<DirectoryImpl> rename(String newPath) => ioWrap(ioDir.rename(newPath))
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new DirectoryImpl(ioFileSystemEntity.path));

  @override
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true}) {
    var ioStream = ioDir.list(recursive: recursive, followLinks: followLinks);

    StreamSubscription<FileSystemEntity> _transformer(
        Stream<io.FileSystemEntity> input, bool cancelOnError) {
      StreamController<FileSystemEntity> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = new StreamController<FileSystemEntity>(onListen: () {
        input.listen((io.FileSystemEntity data) {
          // Duplicate the data.
          if (data is io.File) {
            controller.add(new FileImpl.io(data));
          } else if (data is io.Directory) {
            controller.add(new DirectoryImpl.io(data));
          } else {
            controller.addError(new UnsupportedError(
                'type ${data} ${data.runtimeType} not supported'));
          }
        },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError);
      }, sync: true);
      return controller.stream.listen(null);
    }

    // as Stream<io.FileSystemEntity, FileSystemEntity>;
    return ioStream.transform(
        new StreamTransformer<io.FileSystemEntity, FileSystemEntity>(
            _transformer)) as Stream<FileSystemEntity>;
  }

  @override
  DirectoryImpl get absolute => new DirectoryImpl.io(ioDir.absolute);
}