library fs_shim.utils.src.utils_impl;

import 'dart:async';

//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
import 'package:path/path.dart' as _path;
import '../../fs.dart';
import '../glob.dart';
import '../../src/common/import.dart';
import '../copy.dart';

/*
bool _fsUtilsDebug = false;

bool get fsUtilsDebug => _fsUtilsDebug;

///
/// deprecated to prevent permanent use
///
/// Use:
///
///     fsCopyDebug = true;
///
/// for debugging only
///
@deprecated
set fsUtilsDebug(bool debug) => fsShimUtilsDebug = debug;

set fsShimUtilsDebug(bool debug) => _fsUtilsDebug = debug;
*/

bool _fsCopyDebug = false;
bool get fsCopyDebug => _fsCopyDebug;

///
/// deprecated to prevent permanant use
///
/// Use:
///
///     fsCopyDebug = true;
///
/// for debugging only
///
@deprecated
set fsCopyDebug(bool debug) => _fsCopyDebug = debug;

bool _fsDeleteDebug = false;
bool get fsDeleteDebug => _fsDeleteDebug;

///
/// deprecated to prevent permanent use
///
/// Use:
///
///     fsDeleteDebug = true;
///
/// for debugging only
///
@deprecated
set fsDeleteDebug(bool debug) => _fsDeleteDebug = debug;

// should not be exported
List<Glob> globList(List<String> expressions) {
  List<Glob> globs = [];
  if (expressions != null) {
    for (String expression in expressions) {
      globs.add(new Glob(expression));
    }
  }
  return globs;
}

// for create/copy
class OptionsDeleteMixin {
  bool delete = false;
}

class OptionsCreateMixin {
  bool create = false;
}

class OptionsRecursiveMixin {
  bool recursive = true;
}

class OptionsFollowLinksMixin {
  bool followLinks = true;
}

class OptionsExcludeMixin {
  List<String> exclude;

  // follow glob
  List<Glob> _excludeGlobs;

  List<Glob> get excludeGlobs {
    if (_excludeGlobs == null) {
      _excludeGlobs = globList(exclude);
    }
    return _excludeGlobs;
  }
}

/// Create a directory recursively
Future<Directory> createDirectory(Directory dir,
    {CreateOptions options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteDirectory(dir);
  }
  await dir.create(recursive: options.recursive);
  return dir;
}

/// Create a file recursively
Future<File> createFile(File file, {CreateOptions options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteFile(file);
  }
  await file.create(recursive: options.recursive);
  return file;
}

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions options}) async {
  options ??= defaultDeleteOptions;

  if (await dir.fs.isDirectory(dir.path)) {
    try {
      await dir.delete(recursive: options.recursive);
    } catch (e) {
      if (e is FileSystemException) {
        if (e.status != FileSystemException.statusNotFound) {
          if (options.recursive == false &&
              e.status == FileSystemException.statusNotEmpty) {
            // ok
          } else {
            print('delete $dir failed $e');
          }
        }
      } else {
        print('delete $dir failed $e');
      }
    }
    if (options.create) {
      await dir.create(recursive: true);
    }
  } else {
    throw new ArgumentError('not a directort ($dir)');
  }
}

/// Delete a directory recursively
Future deleteFile(File file, {DeleteOptions options}) async {
  options ??= defaultDeleteOptions;

  if (await file.fs.isFile(file.path)) {
    try {
      await file.delete(recursive: options.recursive);
    } catch (e) {
      if (e is FileSystemException) {
        if (e.status != FileSystemException.statusNotFound) {
          print('delete $file failed $e');
        }
      } else {
        print('delete $file failed $e');
      }
    }
    if (options.create) {
      await file.create(recursive: true);
    }
  } else {
    throw new ArgumentError('not a file ($file)');
  }
}

Future<int> copyDirectoryImpl(Directory src, FileSystemEntity dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    // delete destination first?
    if (options.delete) {
      await dst.delete(recursive: true);
    }
    return await new TopCopy(
        new TopEntity(src.fs, src.path), new TopEntity(dst.fs, dst.path),
        options: options).run();
  } else {
    throw new ArgumentError('not a directory ($src)');
  }
}

Future<Directory> copyDirectory(Directory src, FileSystemEntity dst,
    {CopyOptions options}) async {
  await copyDirectoryImpl(src, dst, options: options);
  return asDirectory(dst);
}

Future<int> copyFileImpl(File src, FileSystemEntity dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isFile(src.path)) {
    // delete destination first?
    if (options.delete) {
      await dst.delete(recursive: true);
    }
    return await new TopCopy(new TopEntity(src.fs, src.parent.path),
        new TopEntity(dst.fs, dst.parent.path),
        options: options).runChild(src.fs.pathContext.basename(src.path),
        dst.fs.pathContext.basename(dst.path));
    //await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw new ArgumentError('not a file ($src)');
  }
}

Future<File> copyFile(File src, FileSystemEntity dst,
    {CopyOptions options}) async {
  await copyFileImpl(src, dst, options: options);
  return asFile(dst);
}

/*
Future<Link> copyLink(Link src, Link dst, {CopyOptions options}) async {
  if (await src.fs.isLink(src.path)) {
    await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw new ArgumentError('not a link ($src)');
  }
  return dst;
}
*/

// Copy a file to its destination
Future<FileSystemEntity> copyFileSystemEntity(
    FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) async {
  await copyFileSystemEntityImpl(src, dst, options: options);
  return dst;
}

Future<int> copyFileSystemEntityImpl(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) async {
  if (await src.fs.isDirectory(src.path)) {
    return await copyDirectoryImpl(asDirectory(src), dst, options: options);
  } else if (await src.fs.isFile(src.path)) {
    return await copyFileImpl(asFile(src), dst, options: options);
  }
  return 0;
}
/*
Future<int> copyFileSystemEntityImpl(FileSystem srcFileSystem, String srcPath,
    FileSystem dstFileSystem, String dstPath,
    {CopyOptions options}) async {
  options ??=
      new CopyOptions(); // old behavior - must be changed at an upper level
  int count = 0;

  if (fsCopyDebug) {
    print("$srcPath => $dstPath");
  }

  if (await srcFileSystem.isLink(srcPath) && (!options.followLinks)) {
    return 0;
  }

  // to ignore?
  if (options.excludeGlobs.isNotEmpty) {
    for (Glob glob in options.excludeGlobs) {
      if (glob.matches(srcPath)) {
        return 0;
      }
    }
  }

  if (await srcFileSystem.isDirectory(srcPath)) {
    Directory dstDirectory = dstFileSystem.newDirectory(dstPath);
    if (!await dstDirectory.exists()) {
      await dstDirectory.create(recursive: true);
      count++;
    }

    // recursive
    if (options.recursive) {
      Directory srcDirectory = srcFileSystem.newDirectory(srcPath);

      List<Future> futures = [];
      await srcDirectory
          .list(recursive: false, followLinks: options.followLinks)
          .listen((FileSystemEntity srcEntity) {
        String basename = srcFileSystem.pathContext.basename(srcEntity.path);
        futures.add(copyFileSystemEntityImpl(srcFileSystem, srcEntity.path,
            dstFileSystem, dstFileSystem.pathContext.join(dstPath, basename),
            options: options).then((int count_) {
          count += count_;
        }));
      }).asFuture();
      await Future.wait(futures);
    }
  } else if (await srcFileSystem.isFile(srcPath)) {
    File srcFile = srcFileSystem.newFile(srcPath);
    File dstFile = dstFileSystem.newFile(dstPath);

    // Try to link first
    // allow link if asked and on the same file system
    if (options.tryToLinkFile &&
        (srcFileSystem == dstFileSystem) &&
        srcFileSystem.supportsFileLink) {
      String target = srcPath;
      // Check if dst is link
      FileSystemEntityType type =
          await dstFileSystem.type(dstPath, followLinks: false);

      bool deleteDst = false;
      if (type != FileSystemEntityType.NOT_FOUND) {
        if (type == FileSystemEntityType.LINK) {
          // check target
          if (await dstFileSystem.newLink(dstPath).target() != target) {
            deleteDst = true;
          } else {
            // nothing to do
            return 0;
          }
        } else {
          deleteDst = true;
        }
      }

      if (deleteDst) {
        await dstFile.delete();
      }

      await dstFileSystem.newLink(dstPath).create(target, recursive: true);
      count++;
      return count;
    }

    // Handle modified date
    if (options.checkSizeAndModifiedDate == true) {
      FileStat srcStat = await srcFile.stat();
      FileStat dstStat = await dstFile.stat();
      if ((srcStat.size == dstStat.size) &&
          (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
        // should be same...
        return 0;
      }
    }

    count += await copyFileContent(srcFile, dstFile);
  }

  return count;
}
*/

/// Copy the file content
Future<int> copyFileContent(File src, File dst) async {
  var inStream = src.openRead();
  StreamSink<List<int>> outSink = dst.openWrite();
  try {
    await inStream.pipe(outSink);
  } catch (_) {
    Directory parent = dst.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    outSink = dst.openWrite();
    inStream = src.openRead();
    await inStream.pipe(outSink);
  }
  return 1;
}

Future emptyOrCreateDirectory(Directory dir) async {
  await dir.delete(recursive: true);
  await dir.create(recursive: true);
}

abstract class EntityNode {
  EntityNode get parent; // can be null
  FileSystem get fs; // cannot be null
  String get top;
  String get sub;
  String get basename;
  Iterable<String> get parts;
  String get path; // full path
  /// create a child
  CopyEntity child(String basename);
  Directory asDirectory();
  File asFile();
  Link asLink();
  Future<bool> isDirectory();
  Future<bool> isFile();
  Future<bool> isLink();
  Future<FileSystemEntityType> type({bool followLinks: true});

  String toString() => '$sub';
}

abstract class EntityNodeFsMixin implements EntityNode {
  Directory asDirectory() => fs.newDirectory(path);
  File asFile() => fs.newFile(path);
  Link asLink() => fs.newLink(path);
  Future<bool> isDirectory() => fs.isDirectory(path);
  Future<bool> isFile() => fs.isFile(path);
  Future<bool> isLink() => fs.isLink(path);
  Future<FileSystemEntityType> type({bool followLinks: true}) =>
      fs.type(path, followLinks: followLinks);
}

abstract class EntityChildMixin implements EntityNode {
  @override
  CopyEntity child(String basename) => new CopyEntity(this, basename);
}

/*
abstract class EntityPartsMixin implements EntityNode {
  String _parts;
  @override
  String get parts => _parts;
}
*/

abstract class EntityPathMixin implements EntityNode {
  String _path;
  @override
  String get path {
    if (_path == null) {
      _path = fs.pathContext.join(top, sub);
    }
    return _path;
  }
}

class TopEntity extends Object
    with EntityPathMixin, EntityNodeFsMixin, EntityChildMixin
    implements EntityNode {
  EntityNode get parent => null;
  final FileSystem fs;
  final String top;
  String get sub => '';
  String get basename => '';
  List<String> get parts => [];

  //TopEntity.parts(this.fs, List<String> parts);
  TopEntity(this.fs, this.top);

  String toString() => top;
}

TopEntity topEntityPath(FileSystem fs, String top) => new TopEntity(fs, top);
TopEntity fsTopEntity(FileSystemEntity entity) =>
    new TopEntity(entity.fs, entity.path);

class CopyEntity extends Object
    with EntityPathMixin, EntityNodeFsMixin, EntityChildMixin
    implements EntityNode {
  EntityNode parent; // cannot be null
  FileSystem get fs => parent.fs;
  String get top => parent.top;
  String basename;
  String _sub;
  String get sub => _sub;
  List<String> _parts;
  Iterable<String> get parts => _parts;

  // Main one not used
  //CopyEntity.main(this.fs, String top) : _top = top;
  CopyEntity(this.parent, String relative) {
    //relative = _path.relative(relative, from: parent.path);
    basename = _path.basename(relative);
    _parts = new List.from(parent.parts);
    _parts.addAll(splitParts(relative));
    _sub = fs.pathContext.join(parent.sub, relative);
  }

  @override
  String toString() => '$sub';
}

abstract class CopyNode {
  EntityNode get src;
  EntityNode get dst;
  CopyOptions get options;
}

abstract class ActionNodeMixin {
  static int _static_id = 0;
}

abstract class CopyNodeMixin implements CopyNode {
  int _id;
  int get id => _id;

  Future<int> runChild(String srcRelative, [String dstRelative]) {
    ChildCopy copy = new ChildCopy(this, srcRelative, dstRelative);

    // exclude?
    return copy.run();
  }
}

class TopCopy extends Object with CopyNodeMixin implements CopyNode {
  CopyOptions _options;
  TopCopy(this.src, this.dst, {CopyOptions options}) {
    _id = ++ActionNodeMixin._static_id;
    _options = options ?? recursiveLinkOrCopyNewerOptions;
  }

  int count = 0;
  CopyOptions get options => _options;
  final TopEntity src;
  final TopEntity dst;
  @override
  String toString() => '[$id] $src => $dst';

  Future<int> run() async {
    if (fsCopyDebug) {
      print(this);
    }
    // Somehow the top folder is accessed using an empty part
    ChildCopy copy = new ChildCopy(this, '');
    return await copy.run();
  }
}

class ChildCopy extends Object
    with CopyNodeMixin, NodeExcludeMixin
    implements CopyNode {
  CopyEntity src;
  CopyEntity dst;
  final CopyNode parent;
  CopyOptions get options => parent.options;

  @override
  String get srcSub => src.sub;

  ChildCopy(this.parent, String srcRelative, [String dstRelative]) {
    _id = ++ActionNodeMixin._static_id;

    dstRelative = dstRelative ?? srcRelative;
    //CopyEntity srcParent = parent.srcEntity;

    src = parent.src.child(srcRelative);
    dst = parent.dst.child(dstRelative);

    //srcEntity = new CopyEntity()
  }
  //List<String> _

  @override
  String toString() => '  [$id] $src => $dst';

  Future<int> run() async {
    int count = 0;
    if (fsCopyDebug) {
      print("$this");
    }

    if (await src.fs.isLink(src.path) && (!options.followLinks)) {
      return 0;
    }

    if (await src.fs.isDirectory(src.path)) {
      // to ignore?
      if (shouldExclude) {
        return 0;
      }

      Directory dstDirectory = dst.asDirectory();
      if (!await dstDirectory.exists()) {
        await dstDirectory.create(recursive: true);
        count++;
      }

      // recursive
      if (options.recursive) {
        Directory srcDirectory = src.asDirectory();

        List<Future> futures = [];
        await srcDirectory
            .list(recursive: false, followLinks: options.followLinks)
            .listen((FileSystemEntity srcEntity) {
          String basename = src.fs.pathContext.basename(srcEntity.path);
          futures.add(runChild(basename).then((int count_) {
            count += count_;
          }));
        }).asFuture();
        await Future.wait(futures);
      }
    } else if (await src.fs.isFile(src.path)) {
      // to ignore?
      if (shouldExcludeFile) {
        return 0;
      }

      File srcFile = src.asFile();
      File dstFile = dst.asFile();

      // Try to link first
      // allow link if asked and on the same file system
      if (options.tryToLinkFile &&
          (src.fs == dst.fs) &&
          src.fs.supportsFileLink) {
        String srcTarget = src.path;
        // Check if dst is link
        FileSystemEntityType type = await dst.type(followLinks: false);

        bool deleteDst = false;
        if (type != FileSystemEntityType.NOT_FOUND) {
          if (type == FileSystemEntityType.LINK) {
            // check target
            if (await dst.asLink().target() != srcTarget) {
              deleteDst = true;
            } else {
              // nothing to do
              return 0;
            }
          } else {
            deleteDst = true;
          }
        }

        if (deleteDst) {
          await dstFile.delete();
        }

        await dst.asLink().create(srcTarget, recursive: true);
        count++;
        return count;
      }

      // Handle modified date
      if (options.checkSizeAndModifiedDate == true) {
        FileStat srcStat = await srcFile.stat();
        FileStat dstStat = await dstFile.stat();
        if ((srcStat.size == dstStat.size) &&
            (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
          // should be same...
          return 0;
        }
      }

      count += await copyFileContent(srcFile, dstFile);
    }

    return count;
  }
}

abstract class NodeExcludeMixin {
  OptionsExcludeMixin get options;
  String get srcSub;

  bool get shouldExclude {
    // to ignore?
    if (options.excludeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in options.excludeGlobs) {
        if (glob.matches(srcSub)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get shouldExcludeFile {
    // to ignore?
    if (options.excludeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in options.excludeGlobs) {
        if (!glob.isDir) {
          if (glob.matches(srcSub)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}