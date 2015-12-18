library fs_shim.utils.src.copy_impl;

import 'dart:async';
//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
import 'package:path/path.dart' as _path;
import '../../fs.dart';
import '../glob.dart';
import '../../src/common/import.dart';
import '../copy.dart';
import 'utils_impl.dart';

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

abstract class CopyNodeMixin implements CopyNode {
  static int _static_id = 0;
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
    _id = ++CopyNodeMixin._static_id;
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

class ChildCopy extends Object with CopyNodeMixin implements CopyNode {
  CopyEntity src;
  CopyEntity dst;
  final CopyNode parent;
  CopyOptions get options => parent.options;

  ChildCopy(this.parent, String srcRelative, [String dstRelative]) {
    _id = ++CopyNodeMixin._static_id;

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

    // to ignore?
    if (options.excludeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in options.excludeGlobs) {
        if (glob.matches(src.sub)) {
          return 0;
        }
      }
    }

    if (await src.fs.isDirectory(src.path)) {
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
