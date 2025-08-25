import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_lib/models/fusion_models.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';

import '../../../../core/models/floor_entity.dart';
import '../../../../core/models/mix_entity.dart';
import '../../../../core/models/project_entity.dart';
import '../../../../core/models/project_metadata_model.dart';
import '../../../../core/services/project_list_manager.dart';
import '../../../dashboard/domain/usecases/delete_project_usecase.dart';
import '../../domain/usecases/load_project_usecases.dart';
import '../../domain/usecases/save_image_to_project_usecase.dart';
import '../../domain/usecases/save_project_usecases.dart';
import '../../domain/usecases/upload_project_usecases.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final SaveProjectUseCase saveProjectUseCase;
  final LoadProjectUseCase loadProjectUseCase;
  final DeleteProjectUseCase deleteProjectUseCase;
  final UploadProjectUseCase uploadProjectUseCase;
  final SaveImageToProjectUseCase saveImageToProjectUseCase;
  final SharedPreferencesHandler prefs;
  final ProjectListManager projectListManager;

  ProjectBloc({
    required this.saveProjectUseCase,
    required this.loadProjectUseCase,
    required this.deleteProjectUseCase,
    required this.uploadProjectUseCase,
    required this.saveImageToProjectUseCase,
    required this.prefs,
    required this.projectListManager,
  }) : super(ProjectInitial()) {
    on<LoadProject>(_onLoadProject);
    on<SaveProject>(_onSaveProject);
    on<DeleteProject>(_onDeleteProject);
    on<UpdateProjectName>(_onUpdateProjectName);
    on<SetCloudId>(_onSetCloudId);
    on<SetSelectedFloorPlan>(_onSetSelectedFloorPlan);
    on<SetSelectedListeningArea>(_onSetSelectedListeningArea);
    on<SetSelectedHardwareComponent>(_onSetSelectedHardwareComponent);
    on<ClearAllSelections>(_onClearAllSelections);
    on<AddFloor>(_onAddFloor);
    on<UpdateFloor>(_onUpdateFloor);
    on<RemoveFloor>(_onRemoveFloor);
    on<SetCurrentFloor>(_onSetCurrentFloor);
    on<AddHardwareComponent>(_onAddHardwareComponent);
    on<UpdateHardwareComponent>(_onUpdateHardwareComponent);
    on<RemoveHardwareComponent>(_onRemoveHardwareComponent);
    on<AddListeningArea>(_onAddListeningArea);
    on<UpdateListeningArea>(_onUpdateListeningArea);
    on<RemoveListeningArea>(_onRemoveListeningArea);
    on<AddMix>(_onAddMix);
    on<UpdateMix>(_onUpdateMix);
    on<RemoveMix>(_onRemoveMix);
    on<AddZone>(_onAddZone);
    on<UpdateZone>(_onUpdateZone);
    on<RemoveZone>(_onRemoveZone);
    on<UploadToCloud>(_onUploadToCloud);
  }

  bool get isAdmin => prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;

  Future<void> _onLoadProject(LoadProject event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    try {
      final ProjectEntity project = await loadProjectUseCase(event.projectName);
      emit(ProjectLoaded(project: project));
    } catch (e) {
      emit(ProjectError('Failed to load project: $e'));
    }
  }

  Future<void> _onSaveProject(SaveProject event, Emitter<ProjectState> emit) async {
    if (state is ProjectLoaded) {
      try {
        final ProjectLoaded currentState = state as ProjectLoaded;
        await saveProjectUseCase(currentState.project);
        // State remains the same, just saved
      } catch (e) {
        emit(ProjectError('Failed to save project: $e'));
      }
    }
  }

  Future<void> _onDeleteProject(DeleteProject event, Emitter<ProjectState> emit) async {
    if (state is ProjectLoaded) {
      try {
        final ProjectLoaded currentState = state as ProjectLoaded;
        await deleteProjectUseCase(projectId: currentState.project.name);
        emit(ProjectInitial());
      } catch (e) {
        emit(ProjectError('Failed to delete project: $e'));
      }
    }
  }

  Future<void> _onUpdateProjectName(UpdateProjectName event, Emitter<ProjectState> emit) async {
    if (state is ProjectLoaded) {
      try {
        final ProjectLoaded currentState = state as ProjectLoaded;
        if (event.newName.isEmpty) {
          emit(const ProjectError('Project name cannot be empty'));
          return;
        }

        final ProjectEntity updatedProject = currentState.project.copyWith(projectName: event.newName);

        if (isAdmin) {
          final ProjectMetadataModel metaData = ProjectMetadataModel(
            fileId: updatedProject.id,
            thumbnailUrl: "",
            projectName: event.newName,
          );
          // Update metadata logic here
          projectListManager.updateProjectMetadataName(
            fileId: updatedProject.id,
            newName: event.newName,
          );
        } else {
          projectListManager.updateProjectMetadataName(
            fileId: updatedProject.cloudId,
            newName: event.newName,
          );
        }

        await saveProjectUseCase(updatedProject);
        emit(currentState.copyWith(project: updatedProject));
      } catch (e) {
        emit(ProjectError('Failed to update project name: $e'));
      }
    }
  }

  void _onSetCloudId(SetCloudId event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final ProjectEntity updatedProject = currentState.project.copyWith(cloudId: event.cloudId);
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onSetSelectedFloorPlan(SetSelectedFloorPlan event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      emit(
        currentState.copyWith(
          selectedFloorPlanId: event.floorPlanId,
          clearListeningArea: true,
          clearHardwareComponent: true,
        ),
      );
    }
  }

  void _onSetSelectedListeningArea(SetSelectedListeningArea event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      emit(
        currentState.copyWith(
          selectedListeningAreaId: event.listeningAreaId,
          clearFloorPlan: true,
          clearHardwareComponent: true,
        ),
      );
    }
  }

  void _onSetSelectedHardwareComponent(SetSelectedHardwareComponent event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      emit(
        currentState.copyWith(
          selectedHardwareComponentId: event.hardwareComponentId,
          clearFloorPlan: true,
          clearListeningArea: true,
        ),
      );
    }
  }

  void _onClearAllSelections(ClearAllSelections event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      emit(
        currentState.copyWith(
          clearFloorPlan: true,
          clearListeningArea: true,
          clearHardwareComponent: true,
        ),
      );
    }
  }

  void _onAddFloor(AddFloor event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors)..add(event.floor);
      final ProjectEntity updatedProject = currentState.project.copyWith(floors: updatedFloors);
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onUpdateFloor(UpdateFloor event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors);
      final int index = updatedFloors.indexWhere((Floor f) => f.id == event.floor.id);
      if (index != -1) {
        updatedFloors[index] = event.floor;
        final ProjectEntity updatedProject = currentState.project.copyWith(floors: updatedFloors);
        emit(currentState.copyWith(project: updatedProject));
      }
    }
  }

  void _onRemoveFloor(RemoveFloor event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors);
      final int floorIndex = updatedFloors.indexWhere((Floor f) => f.id == event.floorId);

      if (floorIndex != -1) {
        final Floor floorToRemove = updatedFloors[floorIndex];
        updatedFloors.removeAt(floorIndex);

        // Add default floor if empty
        if (updatedFloors.isEmpty) {
          updatedFloors.add(
            Floor(
              name: 'Floor 1',
              floorPlan: FloorPlanEntity.defaultFloorPlan,
            ),
          );
        }

        // Remove hardware components in this floor
        final Set<String> areaIds = floorToRemove.listeningAreas.map((ListeningArea a) => a.id).toSet();
        final List<HardwareComponent> updatedHardwareComponents =
            currentState.project.hardwareComponents.where((HardwareComponent hw) {
              final LocationEntity loc = hw.locationEntity;
              return !((loc.listeningAreaId != null && areaIds.contains(loc.listeningAreaId)) || (loc.floorId == floorToRemove.id));
            }).toList();

        final ProjectEntity updatedProject = currentState.project.copyWith(
          floors: updatedFloors,
          hardwareComponents: updatedHardwareComponents,
          currentFloorIndex: currentState.project.currentFloorIndex.clamp(0, updatedFloors.length - 1),
        );

        emit(
          currentState.copyWith(
            project: updatedProject,
            clearFloorPlan: true,
          ),
        );
      }
    }
  }

  void _onSetCurrentFloor(SetCurrentFloor event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      if (event.index >= 0 && event.index < currentState.project.floors.length) {
        final ProjectEntity updatedProject = currentState.project.copyWith(currentFloorIndex: event.index);
        emit(
          currentState.copyWith(
            project: updatedProject,
            clearFloorPlan: true,
            clearListeningArea: true,
            clearHardwareComponent: true,
          ),
        );
      }
    }
  }

  void _onAddHardwareComponent(AddHardwareComponent event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;

      // Add default gain processing block
      final HardwareComponent componentToAdd = event.component;
      if (componentToAdd is Source || componentToAdd is Speaker) {
        final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
          id: 'gain${DateTime.now().millisecondsSinceEpoch}',
          name: 'Gain',
          algorithmId: "gain",
          properties: <PropertySetting>[PropertySetting(name: 'channels', value: 1)],
        );

        if (componentToAdd is Source) {
          componentToAdd.blocks.add(gainBlock);
        } else if (componentToAdd is Speaker) {
          componentToAdd.blocks.add(gainBlock);
        }
      }

      final List<HardwareComponent> updatedComponents = List<HardwareComponent>.from(currentState.project.hardwareComponents)..add(componentToAdd);
      final ProjectEntity updatedProject = currentState.project.copyWith(hardwareComponents: updatedComponents);
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onUpdateHardwareComponent(UpdateHardwareComponent event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<HardwareComponent> updatedComponents = List<HardwareComponent>.from(currentState.project.hardwareComponents);
      final int index = updatedComponents.indexWhere((HardwareComponent c) => c.id == event.component.id);
      if (index != -1) {
        updatedComponents[index] = event.component;
        final ProjectEntity updatedProject = currentState.project.copyWith(hardwareComponents: updatedComponents);
        emit(currentState.copyWith(project: updatedProject));
      }
    }
  }

  void _onRemoveHardwareComponent(RemoveHardwareComponent event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<HardwareComponent> updatedComponents =
          currentState.project.hardwareComponents.where((HardwareComponent c) => c.id != event.componentId).toList();

      // Remove component from mixes if it's a source
      final List<Mix> updatedMixes =
          currentState.project.mixes.map((Mix mix) {
            if (mix.sourceIds.contains(event.componentId)) {
              return mix.copyWith(
                sourceIds: List<String>.from(mix.sourceIds)..remove(event.componentId),
              );
            }
            return mix;
          }).toList();

      final ProjectEntity updatedProject = currentState.project.copyWith(
        hardwareComponents: updatedComponents,
        mixes: updatedMixes,
      );

      emit(
        currentState.copyWith(
          project: updatedProject,
          clearHardwareComponent: true,
        ),
      );
    }
  }

  void _onAddListeningArea(AddListeningArea event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final Floor currentFloor = currentState.project.currentFloor;
      final List<ListeningArea> updatedListeningAreas = List<ListeningArea>.from(currentFloor.listeningAreas)..add(event.listeningArea);

      final Floor updatedFloor = currentFloor.copyWith(listeningAreas: updatedListeningAreas);
      final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors);
      final int floorIndex = updatedFloors.indexWhere((Floor f) => f.id == currentFloor.id);

      if (floorIndex != -1) {
        updatedFloors[floorIndex] = updatedFloor;
        final ProjectEntity updatedProject = currentState.project.copyWith(floors: updatedFloors);
        emit(currentState.copyWith(project: updatedProject));
      }
    }
  }

  void _onUpdateListeningArea(UpdateListeningArea event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final Floor currentFloor = currentState.project.currentFloor;
      final List<ListeningArea> updatedListeningAreas = List<ListeningArea>.from(currentFloor.listeningAreas);
      final int index = updatedListeningAreas.indexWhere((ListeningArea la) => la.id == event.listeningArea.id);

      if (index != -1) {
        updatedListeningAreas[index] = event.listeningArea;
        final Floor updatedFloor = currentFloor.copyWith(listeningAreas: updatedListeningAreas);
        final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors);
        final int floorIndex = updatedFloors.indexWhere((Floor f) => f.id == currentFloor.id);

        if (floorIndex != -1) {
          updatedFloors[floorIndex] = updatedFloor;
          final ProjectEntity updatedProject = currentState.project.copyWith(floors: updatedFloors);
          emit(currentState.copyWith(project: updatedProject));
        }
      }
    }
  }

  void _onRemoveListeningArea(RemoveListeningArea event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final Floor currentFloor = currentState.project.currentFloor;

      // Remove listening area from floor
      final List<ListeningArea> updatedListeningAreas = currentFloor.listeningAreas.where((ListeningArea la) => la.id != event.listeningAreaId).toList();

      // Update hardware components to remove listening area reference
      final List<HardwareComponent> updatedHardwareComponents =
          currentState.project.hardwareComponents.map((HardwareComponent hw) {
            if (hw.locationEntity.listeningAreaId == event.listeningAreaId) {
              return hw.copyWith(
                locationEntity: hw.locationEntity.copyWith(listeningAreaId: ""),
              );
            }
            return hw;
          }).toList();

      final Floor updatedFloor = currentFloor.copyWith(listeningAreas: updatedListeningAreas);
      final List<Floor> updatedFloors = List<Floor>.from(currentState.project.floors);
      final int floorIndex = updatedFloors.indexWhere((Floor f) => f.id == currentFloor.id);

      if (floorIndex != -1) {
        updatedFloors[floorIndex] = updatedFloor;
        final ProjectEntity updatedProject = currentState.project.copyWith(
          floors: updatedFloors,
          hardwareComponents: updatedHardwareComponents,
        );
        emit(
          currentState.copyWith(
            project: updatedProject,
            clearListeningArea: true,
          ),
        );
      }
    }
  }

  void _onAddMix(AddMix event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;

      // Add default gain processing block
      final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
        id: 'gain${DateTime.now().millisecondsSinceEpoch}',
        name: 'Gain',
        algorithmId: "gain",
        properties: <PropertySetting>[PropertySetting(name: 'channels', value: 1)],
      );
      event.mix.processingBlocks.add(gainBlock);

      final List<Mix> updatedMixes = List<Mix>.from(currentState.project.mixes)..add(event.mix);
      final ProjectEntity updatedProject = currentState.project.copyWith(mixes: updatedMixes);
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onUpdateMix(UpdateMix event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Mix> updatedMixes = List<Mix>.from(currentState.project.mixes);
      final int index = updatedMixes.indexWhere((Mix m) => m.id == event.mix.id);
      if (index != -1) {
        updatedMixes[index] = event.mix;
        final ProjectEntity updatedProject = currentState.project.copyWith(mixes: updatedMixes);
        emit(currentState.copyWith(project: updatedProject));
      }
    }
  }

  void _onRemoveMix(RemoveMix event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Mix> updatedMixes = currentState.project.mixes.where((Mix m) => m.id != event.mixId).toList();

      // Remove mix mapping from zones
      final List<Zone> updatedZones =
          currentState.project.zones.map((Zone zone) {
            if (zone.mixIds.contains(event.mixId)) {
              final List<String> updatedMixIds = List<String>.from(zone.mixIds)..remove(event.mixId);
              return zone.copyWith(mixIds: updatedMixIds);
            }
            return zone;
          }).toList();

      final ProjectEntity updatedProject = currentState.project.copyWith(
        mixes: updatedMixes,
        zones: updatedZones,
      );
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onAddZone(AddZone event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;

      // Add default gain processing block
      final ProcessingBlockEntity gainBlock = ProcessingBlockEntity(
        id: 'gain${DateTime.now().millisecondsSinceEpoch}',
        name: 'Gain',
        algorithmId: "gain",
        properties: <PropertySetting>[PropertySetting(name: 'channels', value: 1)],
      );
      event.zone.processingBlocks.add(gainBlock);

      final List<Zone> updatedZones = List<Zone>.from(currentState.project.zones)..add(event.zone);
      final ProjectEntity updatedProject = currentState.project.copyWith(zones: updatedZones);
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  void _onUpdateZone(UpdateZone event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Zone> updatedZones = List<Zone>.from(currentState.project.zones);
      final int index = updatedZones.indexWhere((Zone z) => z.id == event.zone.id);
      if (index != -1) {
        updatedZones[index] = event.zone;
        final ProjectEntity updatedProject = currentState.project.copyWith(zones: updatedZones);
        emit(currentState.copyWith(project: updatedProject));
      }
    }
  }

  void _onRemoveZone(RemoveZone event, Emitter<ProjectState> emit) {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      final List<Zone> updatedZones = currentState.project.zones.where((Zone z) => z.id != event.zoneId).toList();

      // Remove zone reference from hardware components
      final List<HardwareComponent> updatedHardwareComponents =
          currentState.project.hardwareComponents.map((HardwareComponent hw) {
            if (hw.locationEntity.zoneId == event.zoneId) {
              return hw.copyWith(
                locationEntity: hw.locationEntity.copyWith(zoneId: ""),
              );
            }
            return hw;
          }).toList();

      final ProjectEntity updatedProject = currentState.project.copyWith(
        zones: updatedZones,
        hardwareComponents: updatedHardwareComponents,
      );
      emit(currentState.copyWith(project: updatedProject));
    }
  }

  Future<void> _onUploadToCloud(UploadToCloud event, Emitter<ProjectState> emit) async {
    if (state is ProjectLoaded) {
      try {
        final ProjectLoaded currentState = state as ProjectLoaded;
        emit(ProjectLoading());

        final (bool, String) result = await uploadProjectUseCase(currentState.project);

        if (result.$1) {
          emit(currentState); // Return to loaded state
        } else {
          emit(ProjectError('Upload failed: ${result.$2}'));
        }
      } catch (e) {
        emit(ProjectError('Upload failed: $e'));
      }
    }
  }
}
