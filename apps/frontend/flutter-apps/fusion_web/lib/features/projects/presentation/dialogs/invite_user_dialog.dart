// import 'package:flutter/material.dart';
// import 'package:fusion_web/features/projects/data/models/project_model.dart';

// class InviteUserDialog extends StatefulWidget {

//   final ProjectModel project;

//   const InviteUserDialog({
//     super.key,
//     required this.project,
//   });

//   @override
//   State<InviteUserDialog> createState() => _InviteUserDialogState();
// }

// class _InviteUserDialogState extends State<InviteUserDialog> {
//   final _formKey = GlobalKey<FormState>();

//   final List<_InviteRow> _rows = [_InviteRow()];

//   bool _isSubmitting = false;

//   void _addRow() {
//     setState(() {
//       _rows.add(_InviteRow());
//     });
//   }

//   void _removeRow(int index) {
//     if (_rows.length == 1) return;
//     setState(() {
//       _rows.removeAt(index);
//     });
//   }

//   void _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);

//     await Future.delayed(const Duration(milliseconds: 500));

//     if (!mounted) return;

//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     for (final row in _rows) {
//       row.emailController.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
//       contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//       actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),

//       /// TITLE WITH CLOSE
//       title: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             'Invite Users',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),

//       content: SizedBox(
//         width: 560,
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               /// Subtitle
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Invite one or more users to this project by entering their email and selecting a role.',
//                   style: TextStyle(color: Colors.black54),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               /// Dynamic rows
//               ..._rows.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final row = entry.value;

//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 12),
//                   child: Row(
//                     children: [
//                       /// Email
//                       Expanded(
//                         flex: 3,
//                         child: TextFormField(
//                           controller: row.emailController,
//                           decoration: const InputDecoration(
//                             hintText: 'user@example.com',
//                             filled: true,
//                             fillColor: Color(0xFFF5F5F5),
//                             border: OutlineInputBorder(
//                               borderSide: BorderSide.none,
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(8)),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Email required';
//                             }
//                             if (!value.contains('@')) {
//                               return 'Invalid email';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 12),

//                       /// Role
//                       Expanded(
//                         flex: 2,
//                         child: DropdownButtonFormField<String>(
//                           value: row.role,
//                           decoration: const InputDecoration(
//                             filled: true,
//                             fillColor: Color(0xFFF5F5F5),
//                             border: OutlineInputBorder(
//                               borderSide: BorderSide.none,
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(8)),
//                             ),
//                           ),
//                           items: const [
//                             DropdownMenuItem(
//                                 value: 'Viewer', child: Text('Viewer')),
//                             DropdownMenuItem(
//                                 value: 'Editor', child: Text('Editor')),
//                             DropdownMenuItem(
//                                 value: 'Admin', child: Text('Admin')),
//                           ],
//                           onChanged: (value) {
//                             setState(() {
//                               row.role = value!;
//                             });
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 8),

//                       /// Remove button
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => _removeRow(index),
//                       ),
//                     ],
//                   ),
//                 );
//               }),

//               /// Add another button
//               OutlinedButton.icon(
//                 onPressed: _addRow,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Another User'),
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(44),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

//       /// ACTIONS
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isSubmitting ? null : _submit,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.black,
//             foregroundColor: Colors.white,
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           ),
//           child: _isSubmitting
//               ? const SizedBox(
//                   height: 16,
//                   width: 16,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : const Text('Send Invites'),
//         ),
//       ],
//     );
//   }
// }

// /// Helper model
// class _InviteRow {
//   final TextEditingController emailController = TextEditingController();
//   String role = 'Viewer';
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _formKey = GlobalKey<FormState>();
  final List<_InviteRow> _rows = [_InviteRow()];

  void _addRow() {
    setState(() {
      _rows.add(_InviteRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length == 1) return;
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<InviteUserCubit>();

    final userEmails = _rows
        .where((r) => r.selectedUser != null)
        .map((r) => r.selectedUser!.email)
        .toList();

    cubit.inviteUsers(projectId: widget.project.id, userEmails: userEmails);
  }

  @override
  void initState() {
    super.initState();
    context.read<InviteUserCubit>().loadUsers();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),

        /// TITLE
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Invite Users',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

        content: SizedBox(
          width: 800,
          child: Form(
            key: _formKey,
            child: BlocBuilder<InviteUserCubit, BaseState<List<UserModel>>>(
              builder: (context, state) {
                if (state is LoadingState<List<UserModel>>) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is LoadedState<List<UserModel>>) {
                  final users = state.data;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select one or more users to invite.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ..._rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              /// USER DROPDOWN
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<UserModel>(
                                  isExpanded: true,
                                  value: row.selectedUser,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8F8F8),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: users.map((user) {
                                    return DropdownMenuItem<UserModel>(
                                      value: user,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return users.map((user) {
                                      return Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      row.selectedUser = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select user';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              /// ROLE
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: row.role,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Admin',
                                      child: Text('Admin'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Designer',
                                      child: Text('Designer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Technician',
                                      child: Text('Technician'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Contributor',
                                      child: Text('Contributor'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Viewer',
                                      child: Text('Viewer'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      row.role = value!;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeRow(index),
                              ),
                            ],
                          ),
                        );
                      }),

                      OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another User'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  );
                }

                if (state is ErrorState<List<UserModel>>) {
                  return Text(state.message);
                }

                return const SizedBox();
              },
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Invites'),
          ),
        ],
      ),
    );
  }
}

/// Updated helper model
class _InviteRow {
  UserModel? selectedUser;
  String role = 'Viewer';
}
