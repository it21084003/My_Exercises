import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_exercises/screens/home/home_screen_detail_online.dart';
import '../../data/firestore_service.dart';

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

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String? profileDescription;
  String? profilePictureUrl;
  int followersCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> userExercises = [];
  Set<String> forkedExercises = {};
  late bool isFollowing;

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.isFollowing;
    _fetchUserProfile();
    _fetchFollowStatus();
    _fetchExercises();
    _fetchForkedExercises();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _triggerShake() async {
    _animationController.forward(from: 0).then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.uid).get();

      if (userDoc.exists) {
        setState(() {
          profileDescription = userDoc['description'] ?? 'No description';
          profilePictureUrl = userDoc['profilePicture'];
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
          .where('shared', isEqualTo: true)
          .get();

      setState(() {
        userExercises = exerciseSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? timestamp = data['timestamp'] as Timestamp?;
          final dynamic categories = data['categories'] ?? [];

          List<String> categoriesList = [];
          if (categories is List) {
            categoriesList = categories.map((item) => item.toString()).toList();
          }

          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'description': data['description'] ?? 'No description',
            'creatorId': data['creatorId'] ?? 'Unknown',
            'creatorUsername': data['creatorUsername'] ?? 'Unknown',
            'shared': data['shared'] ?? false,
            'timestamp': timestamp,
            'categories': categoriesList,
            'downloadedCount': data['downloadedCount'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching exercises: $e');
    }
  }

  Future<void> _fetchForkedExercises() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      QuerySnapshot forkedSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('forkedExercises')
          .get();

      setState(() {
        forkedExercises = forkedSnapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      print('Error fetching forked exercises: $e');
    }
  }

  Future<void> _toggleFollow() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final followingRef = _firestore.collection('users').doc(currentUser.uid).collection('following');
    final followersRef = _firestore.collection('users').doc(widget.uid).collection('followers');

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

    final exerciseId = exercise['id'];
    final exerciseRef = _firestore.collection('exercises').doc(exerciseId);
    final userForkedRef = _firestore.collection('users').doc(currentUser.uid).collection('forkedExercises');

    try {
      if (forkedExercises.contains(exerciseId)) {
        print("⚠️ Warning: Exercise already forked.");
        return;
      }

      setState(() {
        forkedExercises.add(exerciseId);
        final exerciseIndex = userExercises.indexWhere((e) => e['id'] == exerciseId);
        if (exerciseIndex != -1) {
          userExercises[exerciseIndex]['downloadedCount'] = (userExercises[exerciseIndex]['downloadedCount'] ?? 0) + 1;
        }
      });

      await exerciseRef.update({
        'forkedBy': FieldValue.arrayUnion([currentUser.uid]),
        'downloadedCount': FieldValue.increment(1),
      });

      await userForkedRef.doc(exerciseId).set({
        'exerciseId': exerciseId,
        'title': exercise['title'],
        'description': exercise['description'],
        'creatorId': exercise['creatorId'],
        'creatorUsername': exercise['creatorUsername'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        forkedExercises.remove(exerciseId);
        final exerciseIndex = userExercises.indexWhere((e) => e['id'] == exerciseId);
        if (exerciseIndex != -1) {
          userExercises[exerciseIndex]['downloadedCount'] = (userExercises[exerciseIndex]['downloadedCount'] ?? 1) - 1;
        }
      });
      print('❌ Error forking exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _unforkExercise(Map<String, dynamic> exercise) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Error: No logged-in user.");
      return;
    }

    final exerciseId = exercise['id'];
    final exerciseRef = _firestore.collection('exercises').doc(exerciseId);
    final userForkedRef = _firestore.collection('users').doc(currentUser.uid).collection('forkedExercises');

    try {
      if (!forkedExercises.contains(exerciseId)) {
        print("⚠️ Warning: Exercise not forked.");
        return;
      }

      setState(() {
        forkedExercises.remove(exerciseId);
        final exerciseIndex = userExercises.indexWhere((e) => e['id'] == exerciseId);
        if (exerciseIndex != -1) {
          userExercises[exerciseIndex]['downloadedCount'] = (userExercises[exerciseIndex]['downloadedCount'] ?? 1) - 1;
        }
      });

      await exerciseRef.update({
        'forkedBy': FieldValue.arrayRemove([currentUser.uid]),
        'downloadedCount': FieldValue.increment(-1),
      });

      await userForkedRef.doc(exerciseId).delete();
    } catch (e) {
      setState(() {
        forkedExercises.add(exerciseId);
        final exerciseIndex = userExercises.indexWhere((e) => e['id'] == exerciseId);
        if (exerciseIndex != -1) {
          userExercises[exerciseIndex]['downloadedCount'] = (userExercises[exerciseIndex]['downloadedCount'] ?? 0) + 1;
        }
      });
      print('❌ Error unforking exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    final exerciseId = exercise['id'] as String?;
    if (exerciseId == null || exerciseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise ID is missing!'), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreenDetailOnline(exerciseId: exerciseId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color.fromRGBO(253, 247, 254, 1),
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: isDarkMode ? Colors.grey[900] : const Color.fromRGBO(253, 247, 254, 1),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl!) : null,
                      child: profilePictureUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(profileDescription ?? 'No description available', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Followers: $followersCount', style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 20),
                              Text('Following: $followingCount', style: const TextStyle(fontSize: 14)),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: isFollowing ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _toggleFollow,
              child: Text(isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: userExercises.isEmpty
                        ? Center(child: Text("No exercises available", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey)))
                        : ListView.builder(
                            itemCount: userExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = userExercises[index];
                              final isForked = forkedExercises.contains(exercise['id']);
                              final Timestamp? timestamp = exercise['timestamp'] as Timestamp?;
                              final String timeAgo = timestamp != null ? _firestoreService.formatShortTimeAgo(timestamp.toDate()) : "Unknown";

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                color: isDarkMode ? Colors.grey[900] : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: ListTile(
                                    title: Text(
                                      exercise['title'],
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise['description'],
                                          style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        if (exercise['categories'] != null && exercise['categories'] is List)
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: (exercise['categories'] as List).map((item) {
                                              String category = item.toString();
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: Colors.blue, width: 1),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.download, size: 18, color: Colors.blue),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _formatDownloadCount(exercise['downloadedCount'] ?? 0),
                                                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Text(
                                                    timeAgo,
                                                    style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: AnimatedBuilder(
                                      animation: _shakeAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(!isForked ? _shakeAnimation.value : 0, 0),
                                          child: IconButton(
                                            icon: Icon(
                                              isForked ? Icons.remove_circle_outline : Icons.fork_right,
                                              color: isForked ? Colors.red : Colors.blue,
                                            ),
                                            onPressed: isForked
                                                ? () => _unforkExercise(exercise)
                                                : () => _forkExercise(exercise),
                                          ),
                                        );
                                      },
                                    ),
                                    //onTap: () => _showExerciseDetails(exercise),
                                  ),
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

  String _formatDownloadCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF5E6E6),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF5E6E6),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}