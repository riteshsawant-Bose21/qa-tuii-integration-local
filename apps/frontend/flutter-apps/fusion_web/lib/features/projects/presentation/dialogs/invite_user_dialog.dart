import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/invite_user_viewmodel.dart';
import 'package:fusion_web/features/users/data/models/user_model.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';

class InviteUserDialog extends StatefulWidget {
  final ProjectModel project;

  const InviteUserDialog({super.key, required this.project});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final List<_InviteRow> _rows = [_InviteRow()];

  @override
  void initState() {
    super.initState();
    context.read<InviteUserCubit>().loadUsers();
  }

  void _submit() {
    final cubit = context.read<InviteUserCubit>();

    final userEmails = _rows
        .expand((r) => r.selectedUsers)
        .map((u) => u.email)
        .toList();

    if (userEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one user")),
      );
      return;
    }

    cubit.inviteUsers(projectId: widget.project.id, userEmails: userEmails);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InviteUserCubit, BaseState<List<UserModel>>>(
      listener: (context, state) {
        if (state is SuccessState<List<UserModel>>) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Users invited successfully")),
          );
        }

        if (state is ErrorState<List<UserModel>>) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: context.colorScheme.elevation3, // 👈 border color
            width: 1.2,
          ),
        ),
        backgroundColor: context.colorScheme.elevation1,

        content: SizedBox(
          width: 600,
          height: 420,
          child: BlocBuilder<InviteUserCubit, BaseState<List<UserModel>>>(
            builder: (context, state) {
              if (state is LoadingState<List<UserModel>>) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LoadedState<List<UserModel>>) {
                final users = state.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Invite Users",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const FusionAppText(
                      text:
                          "Search and select one or more users to invite to this project.",
                      style: TextStyle(
                        // color: Colors.black54
                      ),
                    ),

                    const SizedBox(height: 16),

                    _MultiSelectUserField(
                      users: users,
                      selectedUsers: _rows.first.selectedUsers,
                      onChanged: (updated) {
                        setState(() {
                          _rows.first.selectedUsers = updated;
                        });
                      },
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: Colors.black,
                            // foregroundColor: Colors.white,
                          ),
                          child: const Text("Send Invite"),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

/// multi-select model
class _InviteRow {
  List<UserModel> selectedUsers = [];
}

/// multi-select

class _MultiSelectUserField extends StatefulWidget {
  final List<UserModel> users;
  final List<UserModel> selectedUsers;
  final Function(List<UserModel>) onChanged;

  const _MultiSelectUserField({
    required this.users,
    required this.selectedUsers,
    required this.onChanged,
  });

  @override
  State<_MultiSelectUserField> createState() => _MultiSelectUserFieldState();
}

class _MultiSelectUserFieldState extends State<_MultiSelectUserField> {
  final TextEditingController _controller = TextEditingController();
  List<UserModel> filteredUsers = [];
  bool isOpen = false;
  int? hoveredIndex;

  @override
  void initState() {
    super.initState();
    filteredUsers = widget.users;
  }

  void _filter(String query) {
    setState(() {
      filteredUsers = widget.users
          .where(
            (u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void _selectUser(UserModel user) {
    final isSelected = widget.selectedUsers.contains(user);

    List<UserModel> updated;

    if (isSelected) {
      updated = [...widget.selectedUsers]..remove(user);
    } else {
      updated = [...widget.selectedUsers, user];
    }

    widget.onChanged(updated);
  }

  void _removeUser(UserModel user) {
    final updated = [...widget.selectedUsers]..remove(user);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isOpen = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorScheme.elevation3),
              boxShadow: [
                BoxShadow(
                  // color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.selectedUsers.isEmpty
                ? const FusionAppText(text: "Select users...")
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.selectedUsers.map((user) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FusionAppText(text: user.name),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeUser(user),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),

        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              // color: Colors.white,
              border: Border.all(color: context.colorScheme.elevation3),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      prefixIcon: FusionIcon.icon(Icons.search),

                      filled: true,
                      fillColor: context.colorScheme.elevation2,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: context.colorScheme.elevation3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: context.colorScheme.elevation3,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: context.colorScheme.primary, 
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: _filter,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = widget.selectedUsers.contains(user);

                      return MouseRegion(
                        onEnter: (_) => setState(() => hoveredIndex = index),
                        onExit: (_) => setState(() => hoveredIndex = null),
                        child: GestureDetector(
                          onTap: () => _selectUser(user),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: hoveredIndex == index
                                  ? context.colorScheme.elevation3
                                  : context.colorScheme.elevation2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  // backgroundColor: const Color(0xFFE5E7EB),
                                  child: Text(
                                    user.name.substring(0, 2).toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// name
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      /// email with role
                                      Row(
                                        children: [
                                          Flexible(
                                            child: FusionAppText(
                                              text: user.email,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                // color: Colors.black,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 6),

                                          /// DOT
                                          const FusionAppText(
                                            text: "•",
                                            style: TextStyle(
                                              // color: Colors.black,
                                            ),
                                          ),

                                          const SizedBox(width: 6),

                                          /// role
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              // color: const Color.fromARGB(255, 211, 213, 219),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                // color: const Color(0xFFD1D5DB),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              user.role,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (isSelected) const Icon(Icons.check),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
