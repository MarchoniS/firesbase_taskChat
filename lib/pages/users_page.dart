import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

class UsersPage extends StatefulWidget {
  final UserRepository userRepository;

  const UsersPage({Key? key, required this.userRepository}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = widget.userRepository.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Users'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No registered users found.'));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.username),
                subtitle: Text(user.email),
                // Optional: add onTap to open user profile or chat
                onTap: () {
                  // TODO: Implement user profile or start chat
                },
              );
            },
          );
        },
      ),
    );
  }
}
