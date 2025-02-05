import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_exercises/widgets/followers_page.dart';
import 'package:my_exercises/widgets/following_page.dart';
import 'package:my_exercises/widgets/user_profile_screen.dart';
import '../data/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = "";
  bool _isLoading = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Set<String> _following = {}; // To track users the current user is following
  final PageStorageBucket _bucket =
      PageStorageBucket(); // Add PageStorageBucket

  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchFollowing();
    _fetchCounts(); // Fetch count for followers & following

    // Restore previous search input and results from PageStorage
    _searchController.text = PageStorage.of(context)?.readState(context, identifier: "searchInput") ?? '';
    _searchResults = PageStorage.of(context)?.readState(context, identifier: "searchResults") ?? [];
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'] ?? "Unknown User";
            _usernameController.text = _username;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _username = "Error loading name";
          _isLoading = false;
        });
        print("Error fetching username: $e");
      }
    }
  }

  // Fetch follower and following count
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
          _following = followingSnapshot.docs
              .map((doc) => doc.id)
              .toSet(); // Store followed user IDs
        });
      } catch (e) {
        print("Error fetching following list: $e");
      }
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final newUsername = _usernameController.text.trim();

        // Update the username in the 'users' collection
        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
        });

        // Update the 'Created by' field in exercises created by the user
        QuerySnapshot userExercises = await _firestore
            .collection('exercises')
            .where('creatorId', isEqualTo: user.email)
            .get();

        for (var exercise in userExercises.docs) {
          await _firestore.collection('exercises').doc(exercise.id).update({
            'creatorUsername': newUsername,
          });
        }

        setState(() {
          _username = newUsername;
        });
      } catch (e) {
        print('Error updating username: $e');
      }
    }
  }

  void _openSettingsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          message: const Text('Manage your profile settings below.'),
          actions: [
            // Edit Username Option
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showEditUsernameDialog();
              },
              child: const Text('Edit Username'),
            ),

            // Logout Option
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context); // Close the settings menu
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
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showEditUsernameDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Edit Username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _usernameController,
                placeholder: "Enter new username",
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                await _updateUsername();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                  await _authService.logout(); // Perform logout
                  if (!context.mounted) return;
                  // Clear navigation stack and go to the login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login', // Assuming '/' is your login screen route
                    (route) => false, // Remove all previous routes
                  );
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _searchPeople() async {
    String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) return;

    try {
      User? currentUser = _auth.currentUser;

      QuerySnapshot searchSnapshot = await _firestore
          .collection('users')
          .orderBy('username')
          .startAt([searchQuery]).endAt(
              ['$searchQuery\uf8ff']) // Add a high Unicode character
          .get();

      setState(() {
        _searchResults = searchSnapshot.docs
            .where((doc) =>
                doc.id != currentUser?.uid) // Exclude current user's account
            .map((doc) {
          return {
            'uid': doc.id,
            'username': doc['username'],
            'description': doc['description'] ?? 'No description',
          };
        }).toList();

        // Save state in PageStorage
        PageStorage.of(context)?.writeState(context, _searchResults, identifier: "searchResults");
        PageStorage.of(context)?.writeState(context, _searchController.text, identifier: "searchInput");
      });
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final followingRef =
        _firestore.collection('users').doc(user.uid).collection('following');
    final followersRef =
        _firestore.collection('users').doc(targetUid).collection('followers');

    try {
      if (_following.contains(targetUid)) {
        // Unfollow
        await followingRef.doc(targetUid).delete();
        await followersRef
            .doc(user.uid)
            .delete(); // Remove from target user's followers
        setState(() {
          _following.remove(targetUid);
        });
      } else {
        // Follow
        await followingRef.doc(targetUid).set({});
        await followersRef
            .doc(user.uid)
            .set({}); // Add to target user's followers
        setState(() {
          _following.add(targetUid);
        });
      }
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
          isFollowing: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket, // Use the bucket for PageStorage
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Custom Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Menu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: _openSettingsMenu,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Profile Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  child: Row(
                    children: [
                      // Profile Picture
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        child:
                            Icon(Icons.person, size: 25, color: Colors.white),
                      ),
                      const SizedBox(width: 16),

                      // Username Field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add Followers/Following Buttons
              // UI for the buttons with count
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.people, size: 20),
                        label: Text('Followers $_followersCount'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersPage(
                                currentUserId: _auth.currentUser?.uid ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.person_add, size: 20),
                        label: Text('Following $_followingCount'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowingPage(
                                currentUserId: _auth.currentUser?.uid ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Search People
              CupertinoTextField(
                controller: _searchController,
                placeholder: "Search people by username",
                onSubmitted: (_) =>
                    _searchPeople(), // Trigger search on Enter key
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults
                                .clear(); // Clear search results when input is cleared
                          });
                        },
                        child: const Icon(CupertinoIcons.clear,
                            color: Colors.grey),
                      )
                    : null, // Show clear icon only if input is not empty
              ),
              const SizedBox(height: 20),

              // Search Results
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey(
                      'searchResultsList'), // Add a PageStorageKey
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
                      onTap: () =>
                          _viewUserProfile(user['uid'], user['username']),
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
