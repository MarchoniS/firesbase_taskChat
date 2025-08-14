import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task/repositories/task_repository.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../controllers/auth_controller.dart';
import '../repositories/user_repository.dart';

class AuthGate extends StatelessWidget {
  final AuthController authController;

  const AuthGate({Key? key, required this.authController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomePage(
            authController: authController,
            userRepository: UserRepository(),
            taskRepository: TaskRepository(),
          );
        } else {
          return LoginPage(authController: authController);
        }
      },
    );
  }
}
