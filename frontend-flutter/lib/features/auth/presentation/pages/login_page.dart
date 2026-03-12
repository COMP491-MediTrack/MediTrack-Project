import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'MediTrack',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}
