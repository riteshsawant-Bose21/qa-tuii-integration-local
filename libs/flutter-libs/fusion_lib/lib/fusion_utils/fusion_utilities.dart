import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class FusionUtils {
  //singleton
  FusionUtils._internal(){
    _init();
  }

  static final FusionUtils _instance = FusionUtils._internal();

  factory FusionUtils() => _instance;

  //generate  uuid
  static String generateUUID() {
    return const Uuid().v4();
  }

  Directory? appDirectory;

  void _init() async {
    print("directory_set");
    appDirectory = await getFusionAppDirectory();
  }


  //generate a short uuid
  static int shortUUID() {
    return int.parse(shortStringUUID());
  }

  //short String UUID
  static String shortStringUUID() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(999999);
    return '$timestamp$random';
  }

  //generate two random colors from Colors.primaries
  static List<Color> randomColors() => <Color>[
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
  ];

  static bool areVerticesEqualIgnoringOrder(List<Offset> list1, List<Offset> list2) {
    if (list1.length != list2.length) return false;
    return Set<Offset>.from(list1).containsAll(list2);
  }

  static Future<Directory> getFusionAppDirectory() async {
    Directory? appDocDir;
    if (Platform.isWindows) {
      // final userProfile = Platform.environment['USERPROFILE'];
      // appDocDir = userProfile != null ? Directory('$userProfile\\Documents') : await getApplicationDocumentsDirectory();
      appDocDir = await getApplicationSupportDirectory();
    } else {
      appDocDir = await getApplicationDocumentsDirectory();
    }
    return appDocDir;
  }

  static Future<Directory> getOrCreateDirectory(String directoryName) async {
    try {
      Directory appDocDir = await FusionUtils.getFusionAppDirectory();
      Directory rawDataDir = Directory('${appDocDir.path}/$directoryName');

      if (!await rawDataDir.exists()) {
        await rawDataDir.create(recursive: true);
      }

      return rawDataDir;
    } catch (e) {
      throw ('Failed to create raw data directory URL: $e');
    }
  }

  static Future<List<XFile>> generateSharableLogsFiles() async {
    try {
      List<File> filesList = await FusionLogger.getPendingLogsList();
      List<XFile> xFileList = [];
      for (File file in filesList) {
        XFile xFile = generateXFile(file);
        xFileList.add(xFile);
      }
      return xFileList;
    } catch (ex) {
      FusionLogger.log(tag: LogTag.settings, message: "Crash: failed to generate shareble files $ex");
      return [];
    }
  }

  static XFile generateXFile(File file) {
    return XFile(file.path, mimeType: 'text/plain');
  }

  static Future<List<File>> contentsOfDirectory(Directory dir) async {
    return dir.listSync().whereType<File>().toList();
  }

  static Future<File?> zipMultipleFile(List<File> files, String fileName, String path) async {
    try {
      if (files.isEmpty) return null;

      // debug: print sizes before zipping
      for (final f in files) {
        final exists = await f.exists();
        final length = exists ? await f.length() : 0;
        print('zip: candidate file=${f.path} exists=$exists size=$length');
        if (!exists || length == 0) {
          print('zip: WARNING - file is missing or zero length: ${f.path}');
        }
      }

      final archive = Archive();
      for (final file in files) {
        final exists = await file.exists();
        if (!exists) continue;
        final bytes = await file.readAsBytes(); // read content
        // add with basename so zip doesn't include absolute paths
        final nameInArchive = p.basename(file.path);
        archive.addFile(ArchiveFile(nameInArchive, bytes.length, bytes));
      }

      // encode the archive to zip bytes
      final zipData = ZipEncoder().encode(archive);
      if (zipData.isEmpty) {
        print('zip: encode produced no data.');
        return null;
      }

      final zipFile = File(p.join(path, '$fileName.zip'));
      await zipFile.writeAsBytes(zipData, flush: true);

      // quick verification: open the zip and list entries
      final readArchive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      print(
        'zip: created ${zipFile.path} with ${readArchive.length} entries:'
        ' ${readArchive.map((e) => e.name).toList()}',
      );

      return zipFile;
    } catch (e, st) {
      FusionLogger.log(tag: LogTag.settings, message: "Exception : [zipFile] zipping files failed ${e.toString()} \n$st");
      return null;
    }
  }

  /// Zips the project directory referenced by [projectId].
  /// Returns the created zip File, or `null` if the project directory doesn't exist.
  Future<File?> zipProjectDirectory(Directory projectDirectory) async {
    if (!await projectDirectory.exists()) return null;

    try {
      final Archive archive = Archive();

      await for (final FileSystemEntity entity in projectDirectory.list(recursive: true, followLinks: false)) {
        final String relativePath = p.relative(entity.path, from: projectDirectory.path);

        if (entity is File) {
          final List<int> bytes = await entity.readAsBytes();
          final ArchiveFile file = ArchiveFile(relativePath, bytes.length, bytes);

          try {
            final FileStat stat = await entity.stat();
            file.mode = stat.mode;
            file.lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000;
          } catch (_) {
            // Ignore stat errors
          }
          archive.addFile(file);
        }
        // Directory handling removed - files implicitly create directories
      }

      final ZipEncoder encoder = ZipEncoder();
      final List<int> zipData = encoder.encode(archive);

      final String projectBaseName = p.basename(projectDirectory.path);
      final Directory parentDir = projectDirectory.parent;
      final String zipFilePath = p.join(parentDir.path, '$projectBaseName.zip');

      final File zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData, flush: true);

      return zipFile;
    } catch (e, st) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception: [zipFile] zipping files failed $e\n$st");
      return null;
    }
  }

  /// Get duration of any media file (audio/video) across all platforms
  Future<Duration?> getMediaDuration(File file) async {
    try {
      JustAudioMediaKit.ensureInitialized();
      final player = AudioPlayer();

      try {
        await player.setFilePath(file.path);
        final duration = player.duration;
        await player.dispose();
        return duration;
      } catch (e) {
        FusionLogger.log(tag: LogTag.exceptions, message: "Exception: [getMediaDuration] failed to set file path $e");
        await player.dispose();
        return null;
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception: [getMediaDuration] failed to get media duration $e");
      return null;
    }
  }
}
