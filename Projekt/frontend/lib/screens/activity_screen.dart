import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<dynamic> transactions = [];
  Map<int, String> friendNames = {};
  bool isLoading = true;
  String filter = 'Alle'; // 'Alle' oder 'Offen'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
        setState(() {
          transactions = json.decode(transRes.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _settleTransaction(int transactionId) async {
    final url = Uri.parse(
      'http://10.0.2.2:3000/api/transactions/$transactionId/settle',
    );
    try {
      final response = await http.patch(url);
      if (response.statusCode == 200) {
        _fetchData(); // Liste nach erfolgreichem Settle neu laden
      } else {
        if (mounted)
          ScaffoldMessenger.of(
            context,
            ).showSnackBar(SnackBar(content: Text('Fehler: ${response.body}')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;

    // Filter anwenden
    final displayedTransactions = transactions.where((t) {
      if (filter == 'Offen') return t['is_settled'] == 0;
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Aktivität',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Text(
              'Letzte Transaktionen',
              style: TextStyle(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 24),

            // Filter Row
            Row(
              children: [
                _buildFilterButton('Alle', theme),
                const SizedBox(width: 12),
                _buildFilterButton('Offen', theme),
              ],
            ),
            const SizedBox(height: 24),

            // Transaktions-Liste
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedTransactions.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Transaktionen gefunden.',
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedTransactions.length,
                      itemBuilder: (context, index) {
                        final t = displayedTransactions[index];
                        final isIOwe = t['debtor_id'] == userId;
                        final friendId = isIOwe
                            ? t['payer_id']
                            : t['debtor_id'];
                        final friendName =
                            friendNames[friendId] ?? 'Buddy ID $friendId';
                        final isSettled = t['is_settled'] == 1;

                        return _buildTransactionCard(
                          t['id'],
                          t['description'] ?? 'Keine Beschreibung',
                          (t['amount'] as num).toDouble(),
                          isIOwe,
                          friendName,
                          isSettled,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, ThemeData theme) {
    final isActive = filter == title;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => filter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : mutedColor.withAlpha(128),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? theme.textTheme.bodyLarge?.color : mutedColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    int id,
    String desc,
    double amount,
    bool isIOwe,
    String friendName,
    bool isSettled,
  ) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSettled
                      ? 'Beglichen'
                      : (isIOwe
                            ? 'Du schuldest $friendName'
                            : '$friendName schuldet dir'),
                  style: TextStyle(
                    color: isSettled
                        ? mutedColor
                        : (theme.textTheme.bodyMedium?.color ?? mutedColor),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIOwe ? '-' : '+'}€${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSettled
                      ? Colors.grey
                      : (isIOwe ? Colors.redAccent : Colors.greenAccent),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (!isSettled)
                GestureDetector(
                  onTap: () => _settleTransaction(id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: theme.colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
