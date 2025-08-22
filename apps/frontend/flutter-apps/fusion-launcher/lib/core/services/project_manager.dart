import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_launcher/core/models/project_metadata_model.dart';
import 'package:fusion_launcher/core/services/project_list_manager.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/fusion_models.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/dashboard/data/models/upload_file_response_dto.dart';
import '../../features/dashboard/domain/entities/create_project_entity.dart';
import '../models/amplifer.dart';
import '../models/floor_entity.dart';
import '../models/mix_entity.dart';
import '../models/project_entity.dart';
import '../service_locator.dart';
import '../utils/helper.dart';
import '../utils/shared_preference_handler.dart';

class ProjectManager extends ValueNotifier<ProjectEntity> {
  ProjectManager(super.initialProject);

  String? _selectedFloorPlanId;
  String? _selectedListeningAreaId;
  String? _selectedHardwareComponentId;

  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
  final ProjectListManager projectListManager = serviceLocator<ProjectListManager>();

  bool get isAdmin {
    return prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
  }

  _reset() {
    _selectedFloorPlanId = null;
    _selectedListeningAreaId = null;
    _selectedHardwareComponentId = null;
  }

  Floor get _floor => value.currentFloor;

  Floor get currentFloor => value.currentFloor;

  String get projectId => value.id;

  String get projectName => value.name;

  String? get selectedSurfaceId => _selectedListeningAreaId;

  String? get selectedHardwareComponentId => _selectedHardwareComponentId;

  String? get selectedFloorPlanId => _selectedFloorPlanId;

  Floor get selectedFloorPlan {
    if (_selectedFloorPlanId == null) {
      return _floor; // Return the current floor if no specific floor is selected
    }
    return value.floors.firstWhere(
      (Floor f) => f.id == _selectedFloorPlanId,
      orElse: () => _floor,
    );
  }

  ListeningArea? get selectedListeningArea {
    if (_selectedListeningAreaId == null) {
      return null; // Return null if no surface is selected
    }
    return _floor.listeningAreas.firstWhere(
      (ListeningArea s) => s.id == _selectedListeningAreaId,
    );
  }

  HardwareComponent? get selectedHardwareComponent {
    if (_selectedHardwareComponentId == null) {
      return null; // Return null if no hardware component is selected
    }
    return value.hardwareComponents.firstWhere(
      (HardwareComponent s) => s.id == _selectedHardwareComponentId,
    );
  }

  void notifyDataChange() {
    notifyListeners();
  }

  void setCloudId(String cloudId) {
    print("cloudId --------$cloudId");
    value = value.copyWith(cloudId: cloudId);
    notifyListeners();
  }

  void setSelectedFloorPlanId(String? id) {
    clearAllSelection();
    _selectedFloorPlanId = id;
    notifyListeners();
  }

  void setSelectedHardwareComponentId(String? id) {
    clearAllSelection();
    _selectedHardwareComponentId = id;
    notifyListeners();
  }

  void setSelectedSurfaceId(String? id) {
    clearAllSelection();
    _selectedListeningAreaId = id;
    notifyListeners();
  }

  void clearSelectedListeningArea({bool notify = false}) {
    _selectedListeningAreaId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearSelectedHardwareComponent({bool notify = false}) {
    _selectedHardwareComponentId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearSelectedFloor({bool notify = false}) {
    _selectedFloorPlanId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearAllSelection({bool notify = false}) {
    _selectedFloorPlanId = null;
    _selectedListeningAreaId = null;
    _selectedHardwareComponentId = null;
    if (notify) {
      notifyListeners();
    }
  }

  // ─── Floors ────────────────────────────────────────────────────────────────
  void addFloor(Floor floor) {
    value.floors.add(floor);
    notifyListeners();
  }

  void updateFloor(Floor updated) {
    final int idx = value.floors.indexWhere((Floor f) => f.id == updated.id);
    if (idx == -1) return;
    value.floors[idx] = updated;
    notifyListeners();
  }

  void removeFloor(String floorId) {
    clearSelectedFloor();
    final int idx = value.floors.indexWhere((Floor f) => f.id == floorId);
    if (idx == -1) return;
    _deleteHardwareComponentsInFloor(value.floors.elementAt(idx));
    value.floors.removeAt(idx);

    if (value.floors.isEmpty) {
      value.floors.add(
        Floor(
          name: 'Floor 1',
          floorPlan: FloorPlanEntity.defaultFloorPlan,
        ),
      );
    }

    value.currentFloorIndex = value.currentFloorIndex.clamp(
      0,
      value.floors.length - 1,
    );
    notifyListeners();
  }

  bool isFloorEmpty(String floorId) {
    final Floor floor = value.floors.firstWhere((Floor f) => f.id == floorId);
    return floor.listeningAreas.isEmpty &&
        floor.floorPlan.imagePath.isEmpty &&
        value.hardwareComponents.where((HardwareComponent hw) => hw.locationEntity.floorId == floor.id).isEmpty;
  }

  void _deleteHardwareComponentsInFloor(Floor floor) {
    final Set<String> areaIds = floor.listeningAreas.map((ListeningArea a) => a.id).toSet();
    value.hardwareComponents.removeWhere((HardwareComponent hw) {
      final LocationEntity loc = hw.locationEntity;
      return (loc.listeningAreaId != null && areaIds.contains(loc.listeningAreaId)) || (loc.floorId == floor.id);
    });
  }

  void setCurrentFloor(int index) {
    if (index < 0 || index >= value.floors.length) return;
    value.currentFloorIndex = index;
    clearAllSelection();
    notifyListeners();
  }

  void updateFloorList(List<Floor> floors) {
    value = value.copyWith(
      floors: floors,
      currentFloorIndex: value.currentFloorIndex.clamp(0, floors.length - 1),
    );
    notifyListeners();
  }

  // ─── FloorPlan ─────────────────────────────────────────────────────────────
  void updateFloorPlan(FloorPlanEntity plan) {
    _floor.floorPlan = plan;
    notifyListeners();
  }

  // ─── Listening Areas ──────────────────────────────────────────────────────────────
  void addListeningArea(ListeningArea surface) {
    _floor.listeningAreas.add(surface);
    notifyListeners();
  }

  void updateListeningArea(ListeningArea updated) {
    final int i = _floor.listeningAreas.indexWhere(
      (ListeningArea s) => s.id == updated.id,
    );
    if (i == -1) return;
    _floor.listeningAreas[i] = updated;
    notifyListeners();
  }

  void removeListeningArea(String listeningAreaId) {
    clearSelectedListeningArea();

    // Remove the listening area from the floor
    _floor.listeningAreas.removeWhere(
      (ListeningArea s) => s.id == listeningAreaId,
    );

    // Properly update the state with the modified hardwareComponents
    final List<HardwareComponent> updatedHardwareComponents =
        value.hardwareComponents.map((HardwareComponent hw) {
          if (hw.locationEntity.listeningAreaId == listeningAreaId) {
            final HardwareComponent updated = hw.copyWith(
              locationEntity: hw.locationEntity.copyWith(listeningAreaId: ""),
            );
            return updated;
          }
          return hw;
        }).toList();

    // Assign updated hardware list to state
    value = value.copyWith(hardwareComponents: updatedHardwareComponents);
    notifyListeners();
  }

  Floor getFloorByListeningAreaId(String listeningAreaId) {
    return value.floors.firstWhere(
      (Floor f) => f.listeningAreas.any((ListeningArea s) => s.id == listeningAreaId),
    );
  }

  // ----- Mixes ---------------------------
  void addMix(Mix mix) {
    //Add Gain processing block to mix by default
    final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
      id: 'gain${DateTime.now().millisecondsSinceEpoch}',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    );

    mix.processingBlocks.add(gainBlock);

    value.mixes.add(mix);
    notifyListeners();
  }

  void updateMix(Mix updated) {
    final int i = value.mixes.indexWhere((Mix m) => m.id == updated.id);
    if (i == -1) return;
    value.mixes[i] = updated;
    notifyListeners();
  }

  void removeMix(String mixId) {
    value.mixes.removeWhere((Mix m) => m.id == mixId);

    //remove mix mapping from zone value.zones.mixIds
    for (final Zone zone in value.zones) {
      if (zone.mixIds.contains(mixId)) {
        zone.mixIds.remove(mixId);
      }
    }
    notifyListeners();
  }

  //------ Zones ---------------------------
  void addZone(Zone zone) {
    // Add Gain processing block to zone by default
    final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
      id: 'gain${DateTime.now().millisecondsSinceEpoch}',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    );
    zone.processingBlocks.add(gainBlock);

    value.zones.add(zone);
    notifyListeners();
  }

  void updateZone(Zone updated) {
    final int i = value.zones.indexWhere((Zone z) => z.id == updated.id);
    if (i == -1) return;
    value.zones[i] = updated;

    notifyListeners();
  }

  void removeZone(String zoneId) {
    value.zones.removeWhere((Zone z) => z.id == zoneId);

    // remove speakers locationEntity.zoneId  using copyWith
    value = value.copyWith(
      hardwareComponents:
          value.hardwareComponents.map((HardwareComponent hw) {
            if (hw.locationEntity.zoneId == zoneId) {
              return hw.copyWith(
                locationEntity: hw.locationEntity.copyWith(zoneId: ""),
              );
            }
            return hw;
          }).toList(),
    );

    notifyListeners();
  }

  List<ListeningArea> getListeningAreasInZone(String zoneId) {
    final Zone zone = value.zones.firstWhere((Zone z) => z.id == zoneId);

    // loop through all floors and get all listening areas that match the zone's listeningAreasIds
    return value.floors
        .expand(
          (Floor f) => f.listeningAreas,
        )
        .where(
          (ListeningArea a) => zone.listeningAreasIds.contains(a.id),
        )
        .toList();
  }

  // ─── Hardware Components ──────────────────────────────────────────────────────────────
  void addHardwareComponent(HardwareComponent hardwareComponent) {
    //add gain processing block to component by default
    if (hardwareComponent is Source || hardwareComponent is Speaker) {
      final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
        id: 'gain${DateTime.now().millisecondsSinceEpoch}',
        name: 'Gain',
        algorithmId: "gain",
        properties: <PropertySetting>[
          PropertySetting(name: 'channels', value: 1),
        ],
      );

      if (hardwareComponent is Source) {
        hardwareComponent.blocks.add(gainBlock);
      } else if (hardwareComponent is Speaker) {
        hardwareComponent.blocks.add(gainBlock);
      }
    }
    value.hardwareComponents.add(hardwareComponent);
    notifyListeners();
  }

  void updateHardwareComponent(HardwareComponent updated) {
    final int i = value.hardwareComponents.indexWhere(
      (HardwareComponent s) => s.id == updated.id,
    );
    if (i == -1) return;
    value.hardwareComponents[i] = updated;
    notifyListeners();
  }

  void updateHardwareList(List<HardwareComponent> hardwareComponents) {
    // Update every given the hardware given list of hardware components

    for (HardwareComponent updated in hardwareComponents) {
      final int i = value.hardwareComponents.indexWhere(
        (HardwareComponent s) => s.id == updated.id,
      );
      if (i == -1) return;

      value.hardwareComponents[i] = updated;
    }

    notifyListeners();
  }

  void removeHardwareComponent(String componentId) {
    clearSelectedHardwareComponent();

    value.hardwareComponents.removeWhere(
      (HardwareComponent s) => s.id == componentId,
    );

    //if Source remove componentI form all the mixes value
    value = value.copyWith(
      mixes:
          value.mixes.map((Mix mix) {
            if (mix.sourceIds.contains(componentId)) {
              return mix.copyWith(
                sourceIds: List<String>.from(mix.sourceIds)..remove(componentId),
              );
            }
            return mix;
          }).toList(),
    );

    notifyListeners();
  }

  List<HardwareComponent> getHardwareComponentsInFloor(String floorId) {
    final Floor floor = value.floors.firstWhere((Floor f) => f.id == floorId);
    final Set<String> areaIds = floor.listeningAreas.map((ListeningArea a) => a.id).toSet();
    return value.hardwareComponents
        .where(
          (HardwareComponent hw) =>
              (hw.locationEntity.listeningAreaId != null && areaIds.contains(hw.locationEntity.listeningAreaId) ||
                  (hw.locationEntity.floorId != null && hw.locationEntity.floorId == floor.id)),
        )
        .toList();
  }

  List<Speaker> getSpeakersInFloor(String floorId) {
    final List<HardwareComponent> hwComponents = getHardwareComponentsInFloor(
      floorId,
    );
    return hwComponents.whereType<Speaker>().toList();
  }

  //------------Fusion Devices ---------------------------
  void updateFusionDevices(List<FusionDevice> devices) {
    value = value.copyWith(fusionDevices: devices);
    notifyListeners();
  }

  FusionDevice getFusionDeviceFromProject(FusionDevice newDevice) {
    final FusionDevice device = value.fusionDevices.firstWhere((FusionDevice d) => d.id == newDevice.id, orElse: () => newDevice);
    return device;
  }

  void addFusionDevice(FusionDevice device) {
    value.fusionDevices.add(device);
    notifyListeners();
  }

  void updateFusionDevice(FusionDevice updated) {
    final int i = value.fusionDevices.indexWhere(
      (FusionDevice d) => d.id == updated.id,
    );
    if (i == -1) return;
    value.fusionDevices[i] = updated;
    notifyListeners();
  }

  void resetFusionDeviceAssignments(String deviceId) {
    final int i = value.fusionDevices.indexWhere(
      (FusionDevice d) => d.id == deviceId,
    );
    if (i == -1) return;
    final FusionDevice device = value.fusionDevices[i];
    value.fusionDevices[i] = device.copyWith(
      status: FusionDeviceSetupStatus.notStarted,
    );
    print("updated fusion device: ${value.fusionDevices[i]}");
    notifyListeners();
  }

  //-------Amplifiers ----------------------------

  void addAmplifier(Amplifier amplifier) {
    value.amplifiers.add(amplifier);
    notifyListeners();
  }

  void updateAmplifier(Amplifier updated) {
    final int i = value.amplifiers.indexWhere((Amplifier a) => a.id == updated.id);
    if (i == -1) return;
    value.amplifiers[i] = updated;
    notifyListeners();
  }

  void removeAmplifier(String amplifierId) {
    value.amplifiers.removeWhere((Amplifier a) => a.id == amplifierId);
    notifyListeners();
  }

  void updateAmplifierList(List<Amplifier> amplifiers) {
    value = value.copyWith(
      amplifiers: amplifiers,
    );
    notifyListeners();
  }

  //------- Control & Design Mode ----------------------------
  void setControlMode(bool isControlMode) {
    value.isInControlMode = isControlMode;
    notifyListeners();
  }

  //calculate FusionDevices and Amplifiers count
  void calculateProcessorAndAmplifiers() {
    //Get number of HardwareComponents that are Sources or Speakers which has different ListingAreas.listingAreaId which is not null
    final Set<String> uniqueListeningAreaIds =
        value.hardwareComponents
            .where((HardwareComponent hw) => hw is Source || hw is Speaker)
            .map((HardwareComponent hw) => hw.locationEntity.listeningAreaId)
            .whereType<String>()
            .toSet();

    final int fusionDeviceCount = uniqueListeningAreaIds.length;
    //auto generate dummy FusionDevices add them to suggestedFusionDevices
    final List<FusionDevice> suggestedFusionDevices = List<FusionDevice>.generate(
      fusionDeviceCount,
      (int index) => FusionDevice(
        id: 'suggested_fusion_device_$index',
        name: 'Fusion Mini',
        status: FusionDeviceSetupStatus.notStarted,
        location: 'unknown',
      ),
    );

    //auto generate dummy Amplifiers add them to suggestedAmplifiers
    final int amplifierCount = uniqueListeningAreaIds.length;
    final List<Amplifier> suggestedAmplifiers = List<Amplifier>.generate(
      amplifierCount,
      (int index) => Amplifier(
        id: 'suggested_amplifier_$index',
        name: 'Amplifier',
        channels: 4,
        powerPerChannel: 1200,
        color: Colors.green,
      ),
    );

    value = value.copyWith(
      amplifiers: suggestedAmplifiers,
      suggestedFusionDevices: suggestedFusionDevices,
    );

    notifyListeners();
  }

  //-------VIP ----------------------------
  void updateVip(String vip) {
    value = value.copyWith(virtualIP: vip);
    notifyListeners();
  }

  //-------DRO ----------------------------

  void updateDroResponse(Map<String, dynamic> droResponse) {
    value = value.copyWith(droResponse: droResponse);
    notifyListeners();
  }

  // Metadata
  void updateMetadata(ProjectMetadataModel updatedMetadata) {
    value = value.copyWith(metaData: updatedMetadata.toString());
    notifyListeners();
  }

  ProjectMetadataModel get projectMetadata {
    final String metaDataString = value.metaData;
    // if (metaDataString.isEmpty) {
    //   return ProjectMetadataModel(fileId: '', thumbnailUrl: '');
    // }
    final Map<String, dynamic> metaDataMap = jsonDecode(metaDataString);
    return ProjectMetadataModel.fromJson(metaDataMap);
  }

  // ─── Project  ──────────────────────────────────────────────────────────
  Future<Directory> _projectDirectory(String projectName) async {
    final bool adminLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? '/AdminFusionProject' : '/FusionProject';
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory projectDir = Directory('${dir.path}$fusionDirPath/$projectName');

    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    return projectDir;
  }

  Future<File> _localFile(String projectName) async {
    final bool adminLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? '/AdminFusionProject' : '/FusionProject';
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fusionDirPath/$projectName/project_data.json');
  }

  Future<void> saveProject() async {
    final File file = await _localFile(value.name);
    final String jsonStr = jsonEncode(value.toJson());
    print('Saving project to file: $jsonStr');
    print("Project metadata: ${value.metaData}");
    await file.writeAsString(jsonStr);
    print('Project saved successfully!');
  }

  Future<void> deleteProject() async {
    try {
      final File file = await _localFile(value.name);
      if (await file.exists()) {
        await file.delete();
        print('Project deleted successfully');
      } else {
        print('No project file to delete');
      }
    } catch (e) {
      throw ('Error deleting project: $e');
    }
  }

  void updateProjectName(String newName) {
    if (newName.isEmpty) {
      throw ('Project name cannot be empty');
    }
    value = value.copyWith(projectName: newName);
    if (isAdmin) {
      final ProjectMetadataModel metaData = ProjectMetadataModel(
        fileId: value.id,
        thumbnailUrl: "",
        projectName: newName,
      );
      updateMetadata(metaData);
      projectListManager.updateProjectMetadataName(
        fileId: value.id,
        newName: newName,
      );
    } else {
      projectListManager.updateProjectMetadataName(
        fileId: value.cloudId,
        newName: newName,
      );
    }

    saveProject();
    notifyListeners();
  }

  Future<void> loadProject(String projectName) async {
    try {
      _reset();
      final File file = await _localFile(projectName);
      if (!await file.exists()) return;
      final String jsonStr = await file.readAsString();
      print('Loading project from file: $jsonStr');
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      print("map---$map");
      final ProjectEntity loaded = ProjectEntity.fromJson(map);
      super.value = loaded;
      notifyListeners();
      print('Project loaded successfully: ${loaded.name}');
    } catch (e) {
      throw ('Error loading project: $e');
    }
  }

  Future<String> saveImageToProject(String imagePath) async {
    try {
      final Directory fusionDir = await _projectDirectory(value.name);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('${imagesDir.path}/$imageName');
      await imageFile.writeAsBytes(await File(imagePath).readAsBytes());
      print('Image saved to project successfully: ${imageFile.path}');
      final List<String> splits = fusionDir.path.split("/");
      return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
    } catch (e) {
      throw ('Error saving image to project: $e');
    }
  }

  Future<String> saveAssetImageToProject(String assetPath) async {
    try {
      final Directory fusionDir = await _projectDirectory(value.name);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('${imagesDir.path}/$imageName');
      final ByteData data = await rootBundle.load(assetPath);
      await imageFile.writeAsBytes(data.buffer.asUint8List());
      print('Asset image saved to project successfully: ${imageFile.path}');
      final List<String> splits = fusionDir.path.split("/");
      return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
    } catch (e) {
      throw ('Error saving asset image to project: $e');
    }
  }

  Future<File> getImageFromProject(String imageName) async {
    try {
      final Directory fusionDir = await _projectDirectory(value.name);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        throw ('Images directory does not exist');
      }
      final File imageFile = File('${imagesDir.path}/$imageName');
      if (!await imageFile.exists()) {
        throw ('Image file does not exist: ${imageFile.path}');
      }
      return imageFile;
    } catch (e) {
      throw ('Error getting image from project: $e');
    }
  }

  /// sync to cloud
  // Future<(bool success, String message)> uploadProjectToCloud() async {
  //   try {
  //     print("Uploading project to cloud: ${value.name}");
  //     final Directory appDocDir = await getApplicationDocumentsDirectory();
  //     final Directory fusionDir = Directory('${appDocDir.path}/FusionProject/${value.name}');
  //
  //     print("Fusion project directory: ${fusionDir.path}");
  //
  //     /// now update UpdatedAT to now()
  //     final ProjectEntity updatedProject = value.copyWith(updatedAt: DateTime.now());
  //
  //     /// save to local file
  //     final File file = await _localFile(value.name);
  //     final String jsonStr = jsonEncode(updatedProject.toJson());
  //     await file.writeAsString(jsonStr);
  //
  //     print("Project data saved to file: ${file.path}");
  //
  //     /// Zip the folder
  //     /// and prepare it for upload
  //     final File zipFile = await Helper.zipFusionProjectFolder(fusionDir);
  //
  //     /// Upload the zip file
  //     final UploadFileUseCase uploadFileUseCase = serviceLocator<UploadFileUseCase>();
  //     final UpdateProjectUsecase updateProjectUsecase = serviceLocator<UpdateProjectUsecase>();
  //     print("Uploading zip file: ${zipFile.path}");
  //
  //     final ResponseCallback<UploadFileEntity> uploadResponse = await uploadFileUseCase(
  //       filename: value.id, // just to create file name ${value.id}.zip,
  //       filePath: zipFile.path,
  //     );
  //     print('Project update response: ${uploadResponse.success} - ${uploadResponse.message}');
  //     if (!uploadResponse.success) {
  //       if (await zipFile.exists()) {
  //         await zipFile.delete();
  //       }
  //       return (false, 'Error: ${uploadResponse.message}');
  //     }
  //
  //     final ResponseCallback<void> updateResponse = await updateProjectUsecase(
  //       name: value.name,
  //       id: value.cloudId,
  //       description: value.name,
  //       metadata: uploadResponse.data!.fileId,
  //     );
  //
  //     print('Project sync response: ${updateResponse.success} - ${updateResponse.message}');
  //
  //     if (!updateResponse.success) {
  //       if (await zipFile.exists()) {
  //         await zipFile.delete();
  //       }
  //       return (false, 'Error ${updateResponse.message}');
  //     }
  //     return (true, 'Project synced to cloud successfully!');
  //   } catch (e) {
  //     return (false, 'Error syncing project to cloud: $e');
  //   }
  // }

  // ─── Cloud  ──────────────────────────────────────────────────────────

  Future<(bool success, String message)> uploadToCloud() async {
    try {
      print("Uploading project to cloud: ${value.name}");
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory fusionDir = Directory('${appDocDir.path}/FusionProject/${value.name}');

      print("Fusion project directory: ${fusionDir.path}");

      /// now update UpdatedAT to now()
      value.copyWith(updatedAt: DateTime.now());

      await saveProject();

      /// Zip the folder
      /// and prepare it for upload
      final File zipFile = await Helper.zipFusionProjectFolder(fusionDir);

      final String? zipFileID = await uploadFileToCloud(
        filePath: zipFile.path,
      );

      if (zipFileID == null) {
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        return (false, 'Error uploading project to cloud: Failed to upload zip file');
      } else {
        print("Zip file uploaded successfully with ID: $zipFileID");
      }

      String? thumbnailFileId;

      if (value.currentFloor.floorPlan.imagePath.trim().isNotEmpty) {
        thumbnailFileId = await uploadFileToCloud(
          filePath: '${appDocDir.path}/${value.currentFloor.floorPlan.imagePath}',
        );

        if (thumbnailFileId == null) {
          return (false, 'Error uploading project to cloud: Failed to upload floor plan image');
        } else {
          print("Image file uploaded successfully with ID: $thumbnailFileId");
        }
      }

      // Create a ProjectMetadataModel with the uploaded fileId and thumbnailUrl
      final ProjectMetadataModel metaData = ProjectMetadataModel(
        fileId: zipFileID,
        thumbnailUrl: thumbnailFileId ?? "",
        projectName: value.projectName,
      );

      //update the project with the fileId
      final ResponseCallback<void> updateResponse = await updateProjectInCloud(
        name: value.name,
        id: value.cloudId,
        description: value.name,
        metaDataModel: metaData,
      );

      if (updateResponse.success) {
        print('Project uploaded successfully: ${updateResponse.message}');
        // Optionally delete the zip file after upload
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        print("Updated metadata: ${metaData.toString()}");
        updateMetadata(metaData);
        await saveProject();
        // serviceLocator<ProjectListManager>().syncProjectsFromCloud();
        return (true, 'Project uploaded successfully: ${updateResponse.message}');
      } else {
        print('Project update failed: ${updateResponse.message}');
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        return (false, 'Project update failed: ${updateResponse.message}');
      }
    } catch (e) {
      print('Upload error: $e');
      return (false, 'Error uploading project to cloud: $e');
    }
  }

  Future<ResponseCallback<void>> updateProjectInCloud({
    required String name,
    required String id,
    required String description,
    required ProjectMetadataModel metaDataModel,
  }) async {
    try {
      final Map<String, dynamic> formData = <String, dynamic>{
        'name': name,
        'description': description,
        'metadata': metaDataModel.toString(),
      };

      final ResponseCallback<void> responseCallback = await serviceLocator<FusionNetworkClient>().put(
        api: FusionApiEndpoint.projects,
        data: formData,
        additionalPath: id,
      );

      if (responseCallback.success) {
        return ResponseCallback<void>(
          success: true,
          message: responseCallback.message,
        );
      } else {
        throw Exception('Project deletion failed: ${responseCallback.message}');
      }
    } catch (e) {
      print(' Exception in ProjectSourceImpl: $e');
      return ResponseCallback<CreateProjectEntity>(
        success: false,
        message: 'Error creating project: $e',
      );
    }
  }

  Future<String?> uploadFileToCloud({
    required String filePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath),
      });

      final ResponseCallback<UploadFileResponseDto> response = await serviceLocator<FusionNetworkClient>().post(
        api: FusionApiEndpoint.uploadFile,
        data: formData,
        fromJson: UploadFileResponseDto.fromJson,
      );

      if (response.success && response.data != null) {
        return response.data!.fileId;
      } else {
        print('Upload failed: ${response.message}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<Uint8List?> downloadFromCloud({required String fileId}) async {
    try {
      final ResponseCallback<Uint8List> response = await serviceLocator<FusionNetworkClient>().get(
        api: FusionApiEndpoint.fetchFile,
        additionalPath: fileId,
      );

      if (response.success && response.data != null) {
        return response.data as Uint8List;
      } else {
        print('Download failed: ${response.message}');
        return null;
      }
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }
}
