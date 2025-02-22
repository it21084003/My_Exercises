import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_exercises/widgets/users/user_profile_widget.dart';

class FollowingPage extends StatelessWidget {
  final String currentUserId;

  const FollowingPage({super.key, required this.currentUserId});

  Future<List<Map<String, dynamic>>> _fetchFollowing() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .get();

    List<Map<String, dynamic>> following = [];
    for (var doc in snapshot.docs) {
      final userDoc =
          await firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        following.add({
          'uid': doc.id,
          'username': userDoc['username'],
          'description': userDoc['description'] ?? 'No description',
        });
      }
    }
    return following;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFollowing(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Not following anyone yet.'));
          } else {
            final following = snapshot.data!;
            return ListView.builder(
              itemCount: following.length,
              itemBuilder: (context, index) {
                final user = following[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user['username']),
                  subtitle: Text(user['description']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          uid: user['uid'],
                          username: user['username'],
                          isFollowing: true, // ✅ Pass initial follow state
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