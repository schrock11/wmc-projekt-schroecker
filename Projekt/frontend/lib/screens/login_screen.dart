import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // Steuert, ob Login oder Register angezeigt wird
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();
  bool _hasSavedUser = false;

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSavedUser = prefs.containsKey('saved_username') &&
          prefs.containsKey('saved_password');
    });
  }

  Future<void> _authenticateBiometric() async {
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) return;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'App-Zugriff per Fingerabdruck oder Gesichtserkennung',
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        final savedUsername = prefs.getString('saved_username');
        final savedPassword = prefs.getString('saved_password');

        if (savedUsername != null && savedPassword != null) {
          _processAuth(savedUsername, savedPassword, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometrie-Fehler: $e')),
        );
      }
    }
  }

  Future<void> _processAuth(
      String username, String password, bool isLoginRequest) async {
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Benutzername und Passwort eingeben'),
        ),
      );
      return;
    }

    if (!isLoginRequest && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Passwort muss mindestens 6 Zeichen lang sein'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse(
        isLoginRequest
            ? 'http://10.0.2.2:3000/api/login'
            : 'http://10.0.2.2:3000/api/users',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        // Zugangsdaten speichern für späteren biometrischen Login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);

        if (mounted) {
          Provider.of<UserProvider>(
            context,
            listen: false,
          ).setUser(data['id'], data['username']);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } else {
        String message = isLoginRequest
            ? 'Anmeldung fehlgeschlagen. Ungültige Zugangsdaten.'
            : 'Registrierung fehlgeschlagen. Bitte erneut versuchen.';
        try {
          final data = json.decode(response.body);
          message = data['error']?.toString() ?? message;
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & Titel
              Text(
                'DebtBuddy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gemeinsame Ausgaben mit Freunden verwalten',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
              const SizedBox(height: 40),

              // Login / Register Toggle Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isLogin
                                    ? theme.scaffoldBackgroundColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Anmelden',
                                  style: TextStyle(
                                    color: isLogin ? titleColor : mutedColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isLogin
                                    ? theme.scaffoldBackgroundColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Registrieren',
                                  style: TextStyle(
                                    color: !isLogin ? titleColor : mutedColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Username Eingabefeld
                    Text(
                      'Benutzername',
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Benutzername eingeben',
                        hintStyle: TextStyle(color: mutedColor),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: mutedColor,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Eingabefeld
                    Text(
                      'Passwort',
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Passwort eingeben',
                        hintStyle: TextStyle(color: mutedColor),
                        prefixIcon: Icon(Icons.lock_outline, color: mutedColor),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () => _processAuth(
                        _usernameController.text.trim(),
                        _passwordController.text,
                        isLogin,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLogin ? 'Anmelden' : 'Konto erstellen',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Biometrie Button (wird nur angezeigt, wenn Daten gespeichert sind)
                    if (_hasSavedUser) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.fingerprint,
                            size: 50,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: _authenticateBiometric,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}