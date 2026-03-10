import 'package:flutter/material.dart';
import 'package:frontend/theme_provider.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'user_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const DebtBuddyApp(),
    ),
  );
}

class DebtBuddyApp extends StatelessWidget {
  const DebtBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DebtBuddy',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData, 
          home: const LoginScreen(),
        );
      },
    );
  }
}