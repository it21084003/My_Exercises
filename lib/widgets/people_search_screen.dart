import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart';

class PeopleSearchScreen extends StatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => {'id': doc.id, 'username': doc['username']})
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search People")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user['username']),
                          onTap: () {
                            // Navigate to User Profile Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(
                                    uid: user['uid'],
                                    username: user['username'],isFollowing: true,),
                                    
                              ),
                            );
                          },
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
