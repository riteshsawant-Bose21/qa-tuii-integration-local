import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

class ProjectDetailViewmodel extends BaseViewModel<ProjectModel> {
  final String projectId;
  final ProjectsRepository repository;
  ProjectDetailViewmodel({required this.projectId, required this.repository}) {
    load();
  }
  
  Future<void> load() async {
    setLoading();
    try {
      final data = await repository.getProjectById(projectId);
      setLoaded(data);
    } catch (e) {
      setError(e.toString());
    }
  }
}
