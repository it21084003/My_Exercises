import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfilePage extends StatefulWidget {
  final String uid;
  final String username;
  final bool isFollowing;

  const UserProfilePage({
    super.key,
    required this.uid,
    required this.username,
    required this.isFollowing,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? profileDescription;
  String? profilePictureUrl;
  int followersCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> userExercises = [];
  late bool isFollowing;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.isFollowing;
    _fetchUserProfile();
    _fetchFollowStatus();
    _fetchExercises();
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.uid).get();

      if (userDoc.exists) {
        setState(() {
          profileDescription = userDoc['description'] ?? 'No description';
          profilePictureUrl = userDoc['profilePicture'] ?? null;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchFollowStatus() async {
    try {
      QuerySnapshot followersSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('followers')
          .get();

      QuerySnapshot followingSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('following')
          .get();

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot followingDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('following')
            .doc(widget.uid)
            .get();

        setState(() {
          followersCount = followersSnapshot.docs.length;
          followingCount = followingSnapshot.docs.length;
          isFollowing = followingDoc.exists;
        });
      }
    } catch (e) {
      print('Error fetching follow status: $e');
    }
  }

  Future<void> _fetchExercises() async {
    try {
      QuerySnapshot exerciseSnapshot = await _firestore
          .collection('exercises')
          .where('creatorId', isEqualTo: widget.uid)
          .get();

      setState(() {
        userExercises = exerciseSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'description': data['description'] ?? 'No description',
            'creatorId': data['creatorId'] ?? 'Unknown', // Include creatorId
          'creatorUsername': data['creatorUsername'] ?? 'Unknown', // Include creatorUsername
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching exercises: $e');
    }
  }

  Future<void> _toggleFollow() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final followingRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following');
    final followersRef =
        _firestore.collection('users').doc(widget.uid).collection('followers');

    try {
      if (isFollowing) {
        await followingRef.doc(widget.uid).delete();
        await followersRef.doc(currentUser.uid).delete();
        setState(() {
          isFollowing = false;
          followersCount--;
        });
      } else {
        await followingRef.doc(widget.uid).set({});
        await followersRef.doc(currentUser.uid).set({});
        setState(() {
          isFollowing = true;
          followersCount++;
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

Future<void> _forkExercise(Map<String, dynamic> exercise) async {
  User? currentUser = _auth.currentUser;
  if (currentUser == null) {
    print("Error: No logged-in user.");
    return;
  }

  print("Forking Exercise: ${exercise['title']} (ID: ${exercise['id']})");
  print("Forking Exercise: ${exercise['creatorId']} (ID: ${exercise['creatorUsername']})");

  final exerciseRef = _firestore.collection('exercises').doc(exercise['id']);
  final userForkedRef = _firestore
      .collection('users')
      .doc(currentUser.uid)
      .collection('forkedExercises');

  try {
    // Check if the exercise is already forked
    DocumentSnapshot forkCheck = await userForkedRef.doc(exercise['id']).get();
    if (forkCheck.exists) {
      print("⚠️ Warning: Exercise already forked.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already forked this exercise!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Update original exercise: Add user to 'forkedBy' array
    await exerciseRef.update({
      'forkedBy': FieldValue.arrayUnion([currentUser.uid])
    }).then((_) {
      print("ForkedBy array updated in Firestore.");
    });

    // Add forked exercise under the user's "forkedExercises"
    await userForkedRef.doc(exercise['id']).set({
      'exerciseId': exercise['id'],
      'title': exercise['title'],
      'description': exercise['description'],
      'creatorId': exercise['creatorId'],
      'creatorUsername': exercise['creatorUsername'], // Use this field directly
      'timestamp': FieldValue.serverTimestamp(), // Store fork time
    }).then((_) {
      print("Forked exercise added to user's forkedExercises.");
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercise forked successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {}); // Refresh UI
  } catch (e) {
    print('Error forking exercise: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailsPage(
          exerciseId: exercise['id'],
          title: exercise['title'],
          description: exercise['description'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      backgroundImage: profilePictureUrl != null
                          ? NetworkImage(profilePictureUrl!)
                          : null,
                      child: profilePictureUrl == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profileDescription ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Followers: $followersCount',
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 20),
                              Text('Following: $followingCount',
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Follow Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: isFollowing ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _toggleFollow,
              child: Text(
                isFollowing ? 'Unfollow' : 'Follow',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // User's Exercises
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Exercises",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: userExercises.isEmpty
                        ? const Center(
                            child: Text("No exercises available",
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: userExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = userExercises[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    exercise['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(exercise['description']),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.content_copy,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _forkExercise(exercise), // Fork action
                                  ),
                                  onTap: () {
                                    print('Selected Exercise: $exercise');
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailsPage extends StatelessWidget {
  final String exerciseId;
  final String title;
  final String description;

  const ExerciseDetailsPage({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 16)),
            // Additional details for the exercise can be added here
          ],
        ),
      ),
    );
  }
}
