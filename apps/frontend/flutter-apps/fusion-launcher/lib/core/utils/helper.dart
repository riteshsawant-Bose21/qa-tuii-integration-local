import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class Helper {
  static int generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(999999);
    return int.parse('$timestamp$random');
  }

  /// Zips the contents of the given folder and returns the zip file.
  static Future<File> zipFusionProjectFolder(Directory folder) async {
    final Archive archive = Archive();
    final List<FileSystemEntity> files = folder.listSync(recursive: true);

    for (final FileSystemEntity file in files) {
      if (file is File) {
        final String relativePath = file.path.replaceFirst(
          '${folder.path}/',
          '',
        );
        final Uint8List data = await file.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, data.length, data));
      }
    }

    final List<int> zipData = ZipEncoder().encode(archive);
    final File zipFile = File('${folder.path}.zip')
      ..createSync(recursive: true);
    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  /// Unzips the given zip file to the specified destination directory.
  static Future<void> unzipFile(
    Uint8List zipFile,
    Directory destination,
  ) async {
    final Archive archive = ZipDecoder().decodeBytes(zipFile);

    for (final ArchiveFile file in archive) {
      final String filePath = '${destination.path}/${file.name}';
      if (file.isFile) {
        final File outFile = File(filePath)..createSync(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
  }

  static List<Color> randomColors() => <Color>[
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
  ];

  static String formatTimeAgoSimple(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Edited ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return 'Edited ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return 'Edited ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Edited just now';
    }
  }
}
