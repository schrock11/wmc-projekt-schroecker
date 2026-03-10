import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    final url = Uri.parse('http://10.0.2.2:3000/api/users/$userId/friends');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (!mounted) return; // Prüft, ob das Widget noch existiert
        setState(() {
          friends = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Prüft, ob das Widget noch existiert
      setState(() => isLoading = false);
    }
  }

  Future<void> _showAddFriendDialog() async {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Add Friend',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: idController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Buddy-ID',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final friendId = int.tryParse(idController.text.trim());
                if (friendId != null) {
                  await _addFriend(friendId);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addFriend(int friendId) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final url = Uri.parse('http://10.0.2.2:3000/api/friendships');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'friend_id': friendId}),
      );

      if (response.statusCode == 201) {
        _fetchFriends();
      } else {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Friends',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_add,
                      color: Colors.blueAccent,
                    ),
                    onPressed: _showAddFriendDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : friends.isEmpty
                  ? const Center(
                      child: Text(
                        'No friends added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  friend['username'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend['username'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Buddy-ID: ${friend['id']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
}
