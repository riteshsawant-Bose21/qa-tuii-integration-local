// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:archive/archive.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// class ZipExtractor {
//   static const String kFusionProjectDirName = '/FusionProject';
//
//   static Future<void> pickAndExtractZip(BuildContext context) async {
//     // 1️⃣ Pick ZIP file
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['zip'],
//       withData: true,
//     );
//
//     if (result == null) return;
//
//     final pickedFile = result.files.first;
//     final zipBytes = pickedFile.bytes;
//     final zipName = p.basenameWithoutExtension(pickedFile.name);
//
//     if (zipBytes == null) return;
//
//     final String fusionDirPath = kFusionProjectDirName;
//     Directory appDocDir = await FusionUtils.getFusionAppDirectory();
//     final Directory fusionDir = Directory('${appDocDir.path}$fusionDirPath');
//
//
//     // 2️⃣ App documents directory
//    // final documentsDir = await getApplicationDocumentsDirectory();
//
//     // 3️⃣ Create /projects directory
//     // final projectsDir =
//     // Directory(p.join(documentsDir.path, projectsFolderName));
//
//     if (!await fusionDir.exists()) {
//       await fusionDir.create(recursive: true);
//     }
//
//     // 4️⃣ Target directory: projects/zipName
//     final targetDir = Directory(p.join(fusionDir.path, zipName));
//
//     // 5️⃣ Check if project already exists
//     if (await targetDir.exists()) {
//       final overwrite = await _showOverwriteDialog(context, zipName);
//       if (!overwrite) return;
//
//       await targetDir.delete(recursive: true);
//     }
//
//     await targetDir.create(recursive: true);
//
//     // 6️⃣ Extract ZIP
//     final archive = ZipDecoder().decodeBytes(zipBytes);
//
//     for (final file in archive) {
//       final outPath = p.join(targetDir.path, file.name);
//
//       if (file.isFile) {
//         final outFile = File(outPath);
//         await outFile.create(recursive: true);
//         await outFile.writeAsBytes(file.content as Uint8List);
//       } else {
//         await Directory(outPath).create(recursive: true);
//       }
//       print("Folder Path");
//       print(outPath);
//     }
//
//     // 7️⃣ Success feedback
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Project "$zipName" imported successfully'),
//         ),
//       );
//     }
//   }
//
//   /// Overwrite confirmation dialog
//   static Future<bool> _showOverwriteDialog(
//       BuildContext context,
//       String projectName,
//       ) async {
//     return await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: const Text('Overwrite Project?'),
//         content: Text(
//           'A project named "$projectName" already exists.\n\nDo you want to overwrite it?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Overwrite'),
//           ),
//         ],
//       ),
//     ) ??
//         false;
//   }
// }
