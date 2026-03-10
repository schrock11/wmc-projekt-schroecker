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
  String filter = 'All'; // 'All' oder 'Open'

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
      final friendsUrl = Uri.parse('http://10.0.2.2:3000/api/users/$userId/friends');
      final friendsRes = await http.get(friendsUrl);
      if (friendsRes.statusCode == 200) {
        final List<dynamic> friendsList = json.decode(friendsRes.body);
        for (var f in friendsList) {
          friendNames[f['id']] = f['username'];
        }
      }

      // 2. Transaktionen laden
      final transUrl = Uri.parse('http://10.0.2.2:3000/api/users/$userId/transactions');
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
    final url = Uri.parse('http://10.0.2.2:3000/api/transactions/$transactionId/settle');
    try {
      final response = await http.patch(url);
      if (response.statusCode == 200) {
        _fetchData(); // Liste nach erfolgreichem Settle neu laden
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;

    // Filter anwenden
    final displayedTransactions = transactions.where((t) {
      if (filter == 'Open') return t['is_settled'] == 0;
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Activity', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Recent transactions', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),

            // Filter Row
            Row(
              children: [
                _buildFilterButton('All'),
                const SizedBox(width: 12),
                _buildFilterButton('Open'),
              ],
            ),
            const SizedBox(height: 24),

            // Transaktions-Liste
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedTransactions.isEmpty
                      ? const Center(child: Text('No transactions found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: displayedTransactions.length,
                          itemBuilder: (context, index) {
                            final t = displayedTransactions[index];
                            final isIOwe = t['debtor_id'] == userId;
                            final friendId = isIOwe ? t['payer_id'] : t['debtor_id'];
                            final friendName = friendNames[friendId] ?? 'Buddy ID $friendId';
                            final isSettled = t['is_settled'] == 1;

                            return _buildTransactionCard(
                              t['id'],
                              t['description'] ?? 'No Description',
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

  Widget _buildFilterButton(String title) {
    final isActive = filter == title;
    return GestureDetector(
      onTap: () => setState(() => filter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blueAccent : Colors.grey.withOpacity(0.5)),
        ),
        child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTransactionCard(int id, String desc, double amount, bool isIOwe, String friendName, bool isSettled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isSettled 
                    ? 'Settled' 
                    : (isIOwe ? 'You owe $friendName' : '$friendName owes you'),
                  style: TextStyle(color: isSettled ? Colors.grey : Colors.white70, fontSize: 12),
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
                  color: isSettled ? Colors.grey : (isIOwe ? Colors.redAccent : Colors.greenAccent),
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
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}