import 'dart:io';

import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProjectImageViewModel on ProjectViewModel {
  //Add Image to Project
  Future<ResponseCallback<String?>> addImageToProject(String imagePath) async {
    try {
      final ResponseCallback<String> response = await projectManager.saveImageToCurrentProject(imagePath);
      updateProject();
      return response;
    } catch (e) {
      throwError(" Unable to Upload image $e");
      return ResponseCallback<String?>.failure(" Unable to Upload image $e");
    }
  }

  //Add Asset Image to Project
  Future<ResponseCallback<String?>> addAssetImageToProject(String assetPath) async {
    try {
      final ResponseCallback<String> response = await projectManager.saveAssetImageToCurrentProject(assetPath);
      updateProject();
      return response;
    } catch (e) {
      throwError(" Unable to Upload image $e");
      return ResponseCallback<String?>.failure(" Unable to Upload image $e");
    }
  }

  //Get Image from Project
  Future<ResponseCallback<File?>> getImageFromProject(String imageName) async {
    try {
      final ResponseCallback<File> response = await projectManager.getImageFromCurrentProject(imageName);
      return response;
    } catch (e) {
      throwError(" Unable to get image $e");
      return ResponseCallback<File?>.failure(" Unable to get image $e");
    }
  }
}
