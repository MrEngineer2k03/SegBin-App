import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  void _editUser(User user) {
    // Show a dialog to edit user
    _showEditUserDialog(user);
  }

  void _deleteUser(User user) async {
    try {
      await AuthService.deleteUser(user.username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.name ?? user.username} deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name ?? '');
    final departmentController = TextEditingController(text: user.department ?? '');
    final courseController = TextEditingController(text: user.course ?? '');
    final idNumberController = TextEditingController(text: user.idNumber ?? '');
    UserType selectedType = user.type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit User: ${user.name ?? user.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                TextField(
                  controller: idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                ),
                DropdownButtonFormField<UserType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: UserType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == UserType.admin ? 'Admin' : 'User'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedType = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update user in Firestore
                final updatedUser = user.copyWith(
                  name: nameController.text.isNotEmpty ? nameController.text : null,
                  department: departmentController.text.isNotEmpty ? departmentController.text : null,
                  course: courseController.text.isNotEmpty ? courseController.text : null,
                  idNumber: idNumberController.text.isNotEmpty ? idNumberController.text : null,
                  type: selectedType,
                );
                try {
                  await AuthService.saveUserToFirestore(updatedUser);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: AuthService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      color: AppConstants.cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          user.name ?? user.username,
                          style: const TextStyle(color: AppConstants.textColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(color: AppConstants.mutedColor),
                            ),
                            if (user.department != null)
                              Text(
                                '${user.department} - ${user.course ?? ''}',
                                style: const TextStyle(color: AppConstants.mutedColor),
                              ),
                            Text(
                              'Points: ${user.points} | Type: ${user.type == UserType.admin ? 'Admin' : 'User'}',
                              style: const TextStyle(color: AppConstants.mutedColor),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppConstants.brandColor),
                              onPressed: () => _editUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppConstants.dangerColor),
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
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
