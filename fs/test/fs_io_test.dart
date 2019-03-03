@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_io_test;

import 'dart:io' as io;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

import 'fs_test.dart';
import 'test_common.dart';
import 'test_common_io.dart';

void main() {
  FileSystem fs = ioFileSystemTestContext.fs;
  group('io', () {
    test('windows', () {
      expect(isIoWindows(ioFileSystemTestContext), io.Platform.isWindows);
    });
    test('name', () {
      expect(ioFileSystemTestContext.fs.name, 'io');
    });
    test('equals', () {
      // Files cannot be compared!
      expect(io.File("test"), isNot(io.File("test")));
      expect(io.Directory("test"), isNot(io.Directory("test")));
    });
    test('type', () async {
      expect(
          await ioFileSystemTestContext.fs
              .type(join('test', 'fs_io_test.dart')),
          FileSystemEntityType.file);
      expect(await ioFileSystemTestContext.fs.type('test'),
          FileSystemEntityType.directory);
    });
    test('test_path', () async {
      expect(ioFileSystemTestContext.outTopPath,
          join(".dart_tool", "fs_shim", "test"));
      expect(ioFileSystemTestContext.outPath,
          join(ioFileSystemTestContext.outTopPath, joinAll(testDescriptions)));
    });

    group('conversion', () {
      test('file', () {
        io.File ioFile = io.File('file');
        File file = wrapIoFile(ioFile);
        expect(unwrapIoFile(file), ioFile);
      });
      test('dir', () {
        io.Directory ioDirectory = io.Directory('dir');
        Directory dir = wrapIoDirectory(ioDirectory);
        expect(unwrapIoDirectory(dir), ioDirectory);
      });
      test('link', () {
        io.Link ioLink = io.Link('link');
        Link link = wrapIoLink(ioLink);
        expect(unwrapIoLink(link), ioLink);
      });

      test('filesystementity', () {
        io.FileSystemEntity ioFse = io.Link('link');
        FileSystemEntity fse = wrapIoLink(ioFse as io.Link);
        expect(ioFse.path, fse.path);

        ioFse = io.Directory('dir');
        fse = wrapIoDirectory(ioFse as io.Directory);

        ioFse = io.File('file');
        fse = wrapIoFile(ioFse as io.File);
      });

      test('oserror', () {
        const ioOSError = io.OSError();
        OSError osError = wrapIoOSError(ioOSError);
        expect(unwrapIoOSError(osError), ioOSError);
      });

      test('filestat', () async {
        io.FileStat ioFileStat = await io.Directory.current.stat();
        FileStat fileStat = wrapIoFileStat(ioFileStat);
        expect(unwrapIoFileStat(fileStat), ioFileStat);
      });

      test('filesystemexception', () {
        const ioFileSystemException = io.FileSystemException();
        FileSystemException fileSystemException =
            wrapIoFileSystemException(ioFileSystemException);
        expect(unwrapIoFileSystemException(fileSystemException),
            ioFileSystemException);
      });

      test('filemode', () async {
        io.FileMode ioFileMode = io.FileMode.read;
        FileMode fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = io.FileMode.write;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = io.FileMode.append;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);
      });

      test('fileentitytype', () async {
        io.FileSystemEntityType ioFset = io.FileSystemEntityType.notFound;
        FileSystemEntityType fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.file;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.directory;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.link;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);
      });
    });

    group('raw', () {
      test('dir', () async {
        Directory dir = Directory("dir");
        File file = File("file");
        expect(file.fs, fs);
        expect(dir.fs, fs);

        try {
          dir = Directory(join(Directory.current.path,
              "never_exist_such_a_dummy_dir_for_fs_shim_testing"));
          await dir.list().toList();
        } catch (_) {}
      });

      test('filestat', () async {
        io.FileStat ioFileStat = await io.Directory.current.stat();
        FileStat fileStat = await Directory.current.stat();
        expect(fileStat.size, ioFileStat.size);
      });

      test('current', () {
        expect(Directory.current.path, io.Directory.current.path);
      });

      test('FileSystemEntity', () async {
        expect(
            await
            // ignore: avoid_slow_async_io
            FileSystemEntity.isLink(Directory.current.path),
            isFalse);
        expect(
            await
            // ignore: avoid_slow_async_io
            FileSystemEntity.isDirectory(Directory.current.path),
            isTrue);
        expect(
            await
            // ignore: avoid_slow_async_io
            FileSystemEntity.isFile(Directory.current.path),
            isFalse);
        expect(
            await
            // ignore: avoid_slow_async_io
            FileSystemEntity.type(Directory.current.path, followLinks: true),
            FileSystemEntityType.directory);
        expect(
            await
            // ignore: avoid_slow_async_io
            FileSystemEntity.type(Directory.current.path, followLinks: false),
            FileSystemEntityType.directory);
      });
    });

    // All tests
    defineTests(ioFileSystemTestContext);
  });
}
