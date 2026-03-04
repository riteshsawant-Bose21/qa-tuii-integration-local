import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';
import 'package:fusion_web/features/users/data/models/user_model.dart';

class InviteUserCubit extends BaseViewModel<List<UserModel>> {
  final ProjectsRepository repository;

  InviteUserCubit({required this.repository});

  /// Load organisation users
  Future<void> loadUsers() async {
    try {
      setLoading();

      final users = await repository.getOrganisationUsers();

      setLoaded(users);
    } catch (e) {
      setError('Failed to load users: ${e.toString()}');
    }
  }

  /// Invite selected users
  Future<void> inviteUsers({
    required String projectId,
    required List<String> userEmails,
  }) async {
    if (userEmails.isEmpty) {
      setError('Please select at least one user');
      return;
    }

    try {
      setLoading();

      for (final userEmail in userEmails) {
        await repository.addUserToProject(
          projectId: projectId,
          userEmail: userEmail,
        );
      }

      emit(SuccessState<List<UserModel>>());
    } catch (e) {
      setError('Failed to invite users: ${e.toString()}');
    }
  }
}