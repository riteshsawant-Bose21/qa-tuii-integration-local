// import 'package:fusion_web/core/usecases/usecase.dart';
// import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
// import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

// class GetProjectsUseCase implements UseCase<List<ProjectEntity>, NoParams> {
//   final ProjectsRepository repository;

//   const GetProjectsUseCase(this.repository);

//   @override
//   Future<List<ProjectEntity>> call(NoParams params) async {
//     return await repository.getProjects();
//   }
// }

// class GetProjectByIdUseCase implements UseCase<ProjectEntity, String> {
//   final ProjectsRepository repository;

//   const GetProjectByIdUseCase(this.repository);

//   @override
//   Future<ProjectEntity> call(String id) async {
//     return await repository.getProjectById(id);
//   }
// }

// class CreateProjectUseCase implements UseCase<ProjectEntity, ProjectEntity> {
//   final ProjectsRepository repository;

//   const CreateProjectUseCase(this.repository);

//   @override
//   Future<ProjectEntity> call(ProjectEntity project) async {
//     return await repository.createProject(project);
//   }
// }

// class UpdateProjectUseCase implements UseCase<ProjectEntity, ProjectEntity> {
//   final ProjectsRepository repository;

//   const UpdateProjectUseCase(this.repository);

//   @override
//   Future<ProjectEntity> call(ProjectEntity project) async {
//     return await repository.updateProject(project);
//   }
// }

// class DeleteProjectUseCase implements UseCase<void, String> {
//   final ProjectsRepository repository;

//   const DeleteProjectUseCase(this.repository);

//   @override
//   Future<void> call(String id) async {
//     return await repository.deleteProject(id);
//   }
// }

// class SearchProjectsUseCase implements UseCase<List<ProjectEntity>, String> {
//   final ProjectsRepository repository;

//   const SearchProjectsUseCase(this.repository);

//   @override
//   Future<List<ProjectEntity>> call(String query) async {
//     return await repository.searchProjects(query);
//   }
// }
