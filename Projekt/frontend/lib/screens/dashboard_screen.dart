import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalOwed = 0.0;
  double totalCredit = 0.0;
  bool isLoading = true;

  Map<int, String> friendNames = {};
  List<Map<String, dynamic>> topFriends = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }

  Future<void> _fetchDashboardData() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    try {
      // 1. Freunde laden, um IDs in Namen umzuwandeln
      final friendsUrl = Uri.parse(
        'http://10.0.2.2:3000/api/users/$userId/friends',
      );
      final friendsRes = await http.get(friendsUrl);
      if (friendsRes.statusCode == 200) {
        final List<dynamic> friendsList = json.decode(friendsRes.body);
        for (var f in friendsList) {
          friendNames[f['id']] = f['username'];
        }
      }

      // 2. Transaktionen laden
      final transUrl = Uri.parse(
        'http://10.0.2.2:3000/api/users/$userId/transactions',
      );
      final transRes = await http.get(transUrl);

      if (transRes.statusCode == 200) {
        final List<dynamic> transactions = json.decode(transRes.body);

        double tempOwed = 0.0;
        double tempCredit = 0.0;
        Map<int, double> balances = {}; // friendId -> offener Saldo

        for (var t in transactions) {
          if (t['is_settled'] == 0) {
            double amount = (t['amount'] as num).toDouble();
            int friendId;

            if (t['payer_id'] == userId) {
              tempCredit += amount;
              friendId = t['debtor_id'];
              balances[friendId] = (balances[friendId] ?? 0) + amount;
            } else if (t['debtor_id'] == userId) {
              tempOwed += amount;
              friendId = t['payer_id'];
              balances[friendId] = (balances[friendId] ?? 0) - amount;
            }
          }
        }

        // Top Freunde aggregieren
        List<Map<String, dynamic>> calculatedTopFriends = [];
        balances.forEach((id, balance) {
          if (balance != 0) {
            // Nur eintragen, wenn es offene Schulden gibt
            calculatedTopFriends.add({
              'id': id,
              'name': friendNames[id] ?? 'Buddy ID $id',
              'balance':
                  balance, // Positiv: Freund schuldet dir, Negativ: Du schuldest dem Freund
            });
          }
        });

        // Nach höchstem Betrag (absolut) absteigend sortieren
        calculatedTopFriends.sort(
          (a, b) => (b['balance'] as double).abs().compareTo(
            (a['balance'] as double).abs(),
          ),
        );

        // Auf maximal 3 limitieren
        if (calculatedTopFriends.length > 3) {
          calculatedTopFriends = calculatedTopFriends.sublist(0, 3);
        }

        if (mounted) {
          setState(() {
            totalOwed = tempOwed;
            totalCredit = tempCredit;
            topFriends = calculatedTopFriends;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<UserProvider>(context).username ?? 'User';
    final totalBalance = totalCredit - totalOwed;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;
    final accentColor = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Willkommen, $username',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 30),

            // Balance Card
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      'Gesamtsaldo',
                      style: TextStyle(color: mutedColor, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: totalBalance < 0
                            ? Colors.redAccent
                            : Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalBalance < 0 ? '↘ Du schuldest' : '↗ Dir wird geschuldet',
                      style: TextStyle(
                        color: totalBalance < 0
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Schulden gesamt',
                              style: TextStyle(color: mutedColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalOwed.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Guthaben gesamt',
                              style: TextStyle(color: mutedColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalCredit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),

            // Top Friends Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Freunde',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                Icon(Icons.trending_up, color: mutedColor),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Top Friends List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : topFriends.isEmpty
                  ? Center(
                      child: Text(
                        'Keine offenen Salden mit Freunden.',
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: topFriends.length,
                      itemBuilder: (context, index) {
                        final friend = topFriends[index];
                        final double balance = friend['balance'];
                        final bool isIOwe = balance < 0;
                        final displayAmount = balance.abs();
                        final initials = _getInitials(friend['name']);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildFriendTile(
                            initials,
                            friend['name'],
                            friend['id'].toString(),
                            '${isIOwe ? '-' : '+'}\$${displayAmount.toStringAsFixed(2)}',
                            isIOwe ? 'du schuldest' : 'schuldet dir',
                            isIOwe ? Colors.redAccent : Colors.greenAccent,
                            theme,
                            accentColor,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Hilfs-Widget für die Listen-Einträge
  Widget _buildFriendTile(
    String initials,
    String name,
    String id,
    String amount,
    String subText,
    Color amountColor,
    ThemeData theme,
    Color accentColor,
  ) {
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(id, style: TextStyle(color: mutedColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(subText, style: TextStyle(color: mutedColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
