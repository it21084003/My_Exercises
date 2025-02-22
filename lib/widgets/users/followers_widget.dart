import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_exercises/widgets/users/user_profile_widget.dart';

class FollowersPage extends StatelessWidget {
  final String currentUserId;

  const FollowersPage({super.key, required this.currentUserId});

  Future<List<Map<String, dynamic>>> _fetchFollowers() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followers')
        .get();

    List<Map<String, dynamic>> followers = [];
    for (var doc in snapshot.docs) {
      final userDoc = await firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        followers.add({
          'uid': doc.id,
          'username': userDoc['username'],
          'description': userDoc['description'] ?? 'No description',
        });
      }
    }
    return followers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFollowers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No followers yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            final followers = snapshot.data!;
            return ListView.builder(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                final follower = followers[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    follower['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(follower['description']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to the UserProfilePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          uid: follower['uid'],
                          username: follower['username'],
                          isFollowing: true, // Assume the user is following them
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}