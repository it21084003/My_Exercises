import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_exercises/widgets/users/followers_widget.dart';
import 'package:my_exercises/widgets/users/following_widget.dart';
import 'package:my_exercises/widgets/users/user_profile_widget.dart';
import '../../data/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = "";
  String? profileDescription = "";
  int _points = 0;
  String _level = "Beginner";
  List<String> _badges = [];
  bool _isLoading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Set<String> _following = {};
  final PageStorageBucket _bucket = PageStorageBucket();

  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchFollowing();
    _fetchCounts();
    _searchController.text = PageStorage.of(context).readState(context, identifier: "searchInput") ?? '';
    _searchResults = PageStorage.of(context).readState(context, identifier: "searchResults") ?? [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'] ?? "Unknown User";
            profileDescription = userDoc['description'] ?? 'No description';
            _points = userDoc['points'] ?? 0;
            _level = userDoc['level'] ?? 'Beginner';
            _badges = List<String>.from(userDoc['badges'] ?? []);
            _usernameController.text = _username;
            _descriptionController.text = profileDescription ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _username = "Error loading name";
          _isLoading = false;
        });
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> _fetchCounts() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot followersSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('followers')
            .get();

        QuerySnapshot followingSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('following')
            .get();

        setState(() {
          _followersCount = followersSnapshot.docs.length;
          _followingCount = followingSnapshot.docs.length;
        });
      } catch (e) {
        print("Error fetching follower/following count: $e");
      }
    }
  }

  Future<void> _fetchFollowing() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot followingSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('following')
            .get();

        setState(() {
          _following = followingSnapshot.docs.map((doc) => doc.id).toSet();
        });
      } catch (e) {
        print("Error fetching following list: $e");
      }
    }
  }

  void _openSettingsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          message: const Text('Manage your profile settings below.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showEditProfileDialog();
              },
              child: const Text('Edit Profile'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                bool confirmLogout = await _showLogoutDialog(context);
                if (confirmLogout) {
                  await _authService.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              child: const Text('Logout'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // TODO: Implement profile image picker
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, size: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _updateProfile(_usernameController.text.trim(), _descriptionController.text.trim());
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfile(String newUsername, String newDescription) async {
    if (newUsername.isEmpty || newDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and description cannot be empty.')));
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
          'description': newDescription,
        });

        QuerySnapshot userExercises = await _firestore.collection('exercises').where('creatorId', isEqualTo: user.uid).get();

        for (var exercise in userExercises.docs) {
          await _firestore.collection('exercises').doc(exercise.id).update({'creatorUsername': newUsername});
        }

        setState(() {
          _username = newUsername;
          profileDescription = newDescription;
        });
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
      }
    }
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Logout'),
                onPressed: () async {
                  await _authService.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ],
          ),
        ) ?? false;
  }

  Future<void> _searchPeople() async {
    String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) return;

    try {
      User? currentUser = _auth.currentUser;

      QuerySnapshot searchSnapshot = await _firestore
          .collection('users')
          .orderBy('username')
          .startAt([searchQuery]).endAt(['$searchQuery\uf8ff'])
          .get();

      setState(() {
        _searchResults = searchSnapshot.docs
            .where((doc) => doc.id != currentUser?.uid)
            .map((doc) => {
                  'uid': doc.id,
                  'username': doc['username'],
                  'description': doc['description'] ?? 'No description',
                }).toList();

        PageStorage.of(context).writeState(context, _searchResults, identifier: "searchResults");
        PageStorage.of(context).writeState(context, _searchController.text, identifier: "searchInput");
      });
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final followingRef = _firestore.collection('users').doc(user.uid).collection('following');
    final followersRef = _firestore.collection('users').doc(targetUid).collection('followers');

    try {
      if (_following.contains(targetUid)) {
        // Unfollow
        await followingRef.doc(targetUid).delete();
        await followersRef.doc(user.uid).delete();
        setState(() {
          _following.remove(targetUid);
          _followingCount--;
        });
      } else {
        // Follow
        await followingRef.doc(targetUid).set({});
        await followersRef.doc(user.uid).set({});
        setState(() {
          _following.add(targetUid);
          _followingCount++;
        });
      }
      // Refresh follow status after toggling
      _fetchFollowing();
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  void _viewUserProfile(String uid, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          uid: uid,
          username: username,
          isFollowing: _following.contains(uid),
        ),
      ),
    ).then((_) {
      // Refresh state when returning from UserProfilePage
      _fetchFollowing();
      _fetchCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Menu", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.settings, color: isDarkMode ? Colors.grey : Colors.black),
                    onPressed: _openSettingsMenu,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, size: 25, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(profileDescription ?? 'No description available', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Points: $_points', style: const TextStyle(fontSize: 16)),
                          Text('Level: $_level', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.people, size: 20),
                        label: Text('Followers $_followersCount'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FollowersPage(currentUserId: _auth.currentUser?.uid ?? '')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.person_add, size: 20),
                        label: Text('Following $_followingCount'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FollowingPage(currentUserId: _auth.currentUser?.uid ?? '')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _searchController,
                placeholder: "Search people by username",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onSubmitted: (_) => _searchPeople(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults.clear();
                          });
                        },
                        child: const Icon(CupertinoIcons.clear, color: Colors.grey),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey('searchResultsList'),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isFollowing = _following.contains(user['uid']);
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(user['username']),
                      subtitle: Text(user['description']),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _toggleFollow(user['uid']),
                        child: Text(
                          isFollowing ? 'Unfollow' : 'Follow',
                          style: TextStyle(
                            color: isFollowing ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _viewUserProfile(user['uid'], user['username']),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}