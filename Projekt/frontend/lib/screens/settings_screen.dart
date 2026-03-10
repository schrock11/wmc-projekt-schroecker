import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 8),
            const Text('Manage your account', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Account Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userProvider.username ?? 'User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  const Text('Your Buddy-ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userProvider.userId?.toString() ?? '---',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: theme.textTheme.bodyLarge?.color),
                      ),
                      Icon(Icons.share, color: theme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Share this ID with friends to connect', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 16),
            
            // Theme List
            Expanded(
              child: ListView(
                children: [
                  _buildThemeTile(context, 'Light', 'Clean and minimal', AppTheme.light, themeProvider),
                  _buildThemeTile(context, 'Dark', 'Easy on the eyes', AppTheme.dark, themeProvider),
                  _buildThemeTile(context, 'Matrix Green', 'Hacker style', AppTheme.matrix, themeProvider),
                  _buildThemeTile(context, 'High-Contrast', 'Maximum readability', AppTheme.highContrast, themeProvider),
                  _buildThemeTile(context, 'Ocean Blue', 'Deep sea vibes', AppTheme.ocean, themeProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, String title, String subtitle, AppTheme themeType, ThemeProvider provider) {
    final isSelected = provider.currentTheme == themeType;
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: theme.primaryColor) 
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () => provider.setTheme(themeType),
    );
  }
}