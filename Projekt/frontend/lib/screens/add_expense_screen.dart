import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  bool isIOwe = true; // true = Ich schulde, false = Mir wird geschuldet
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<dynamic> friends = [];
  int? selectedFriendId;
  bool isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  // Freunde aus dem Backend laden, um sie im Dropdown anzuzeigen
  Future<void> _fetchFriends() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    final url = Uri.parse('http://10.0.2.2:3000/api/users/$userId/friends');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          friends = json.decode(response.body);
          isLoadingFriends = false;
        });
      }
    } catch (e) {
      print('Error fetching friends: $e');
      setState(() => isLoadingFriends = false);
    }
  }

  // Transaktion an das Backend senden
  Future<void> _submitTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0 || selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen gültigen Betrag eingeben und einen Freund auswählen.'),
        ),
      );
      return;
    }

    final myId = Provider.of<UserProvider>(context, listen: false).userId;

    // Logik: Wer ist Payer (zahlt) und wer ist Debtor (schuldet)?
    final payerId = isIOwe ? selectedFriendId : myId;
    final debtorId = isIOwe ? myId : selectedFriendId;

    final url = Uri.parse('http://10.0.2.2:3000/api/transactions');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'payer_id': payerId,
          'debtor_id': debtorId,
          'amount': amount,
          'description': _descController.text.isEmpty
              ? 'Keine Beschreibung'
              : _descController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Schließt den Screen und gibt "true" zurück (für den Refresh)
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Fehler: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
          ).showSnackBar(SnackBar(content: Text('Verbindung fehlgeschlagen: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(170) ?? Colors.grey;
    final activeColor = isIOwe ? Colors.redAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Ausgabe hinzufügen', style: TextStyle(color: titleColor)),
        iconTheme: IconThemeData(color: titleColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transaktionstyp',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Toggle Buttons (I owe / They owe me)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isIOwe = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isIOwe ? Colors.redAccent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '↘ Ich schulde',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isIOwe = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isIOwe
                              ? Colors.greenAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '↗ Mir wird geschuldet',
                          style: TextStyle(
                            color: Colors.greenAccent,
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

            Text('Betrag', style: TextStyle(color: mutedColor, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: titleColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '€ ',
                prefixStyle: TextStyle(color: titleColor, fontSize: 24),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Beschreibung',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: TextStyle(color: titleColor),
              decoration: InputDecoration(
                hintText: 'Wofür ist das?',
                hintStyle: TextStyle(color: mutedColor),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Freund auswählen',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            isLoadingFriends
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: titleColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    value: selectedFriendId,
                    hint: Text(
                      'Freund auswählen...',
                      style: TextStyle(color: mutedColor),
                    ),
                    items: friends.map<DropdownMenuItem<int>>((friend) {
                      return DropdownMenuItem<int>(
                        value: friend['id'],
                        child: Text(friend['username']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFriendId = value;
                      });
                    },
                  ),

            const Spacer(),

            // Submit Button
            ElevatedButton(
              onPressed: _submitTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Schuld hinzufügen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
