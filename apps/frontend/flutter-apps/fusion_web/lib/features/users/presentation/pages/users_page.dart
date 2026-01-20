import 'package:flutter/material.dart';
import 'package:fusion_web/features/users/presentation/viewmodels/users_viewmodel.dart';
import 'package:fusion_web/features/users/data/datasources/users_datasource.dart';
import 'package:fusion_web/features/users/data/repositories/users_repository_impl.dart';
import 'package:fusion_web/features/users/domain/usecases/users_usecases.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late UsersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    // Dependency injection setup - this is the MVVM pattern you can follow
    final remoteDataSource = UsersRemoteDataSource();
    final localDataSource = UsersLocalDataSource();
    final repository = UsersRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    _viewModel = UsersViewModel(
      getUsersUseCase: GetUsersUseCase(repository),
      getUserByIdUseCase: GetUserByIdUseCase(repository),
      createUserUseCase: CreateUserUseCase(repository),
      updateUserUseCase: UpdateUserUseCase(repository),
      deleteUserUseCase: DeleteUserUseCase(repository),
      searchUsersUseCase: SearchUsersUseCase(repository),
    );

    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users Management',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'This is the Users module following MVVM Clean Architecture pattern.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          // Example of reactive UI with ListenableBuilder
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, child) {
                if (_viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_viewModel.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load users',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _viewModel.loadUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show users list or empty state
                final users = _viewModel.users;
                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No users found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name[0].toUpperCase()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Text(user.role),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
