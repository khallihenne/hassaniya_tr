import 'package:flutter/material.dart';
import 'package:hassaniya_translation/pages%20/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;

  // Identifiants valides
  final String validEmail = '23021@esp.mr';
  final String validPassword = '23021kh';

  void login() {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (email == validEmail.toLowerCase() && password == validPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() {
        errorMessage = 'Email ou mot de passe incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Logo SMCE
            Image.asset(
              'assets/images/img.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Logo non trouvé',
                  style: TextStyle(color: Colors.red),
                );
              },
            ),
            const SizedBox(height: 30),

            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: login,
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
