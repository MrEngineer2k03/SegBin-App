import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../constants/app_constants.dart';
import '../screens/new_home_screen.dart';
import 'storage_service.dart';
import 'reward_service.dart';

class AuthService {
  static User? _currentUser;
  static bool _isAdmin = false;
  static final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersKey = 'auth_users';
  static const String _currentUserKey = 'current_user';
  static const String _usersCollection = 'users';

  static User? get currentUser => _currentUser;
  static bool get isAdmin => _isAdmin;
  static bool get isStaff => _currentUser?.type == UserType.staff;
  static bool get isLoggedIn => _currentUser != null;

  // Store the user change callback to notify when user data changes
  static Function(User?)? _onUserChanged;

  // Initialize auth state listener
  static void initializeAuthListener(Function(User?) onUserChanged) {
    _onUserChanged = onUserChanged;
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          // Try to load user data from Firestore first, then fallback to local storage
          User? user = await _loadUserFromFirestore(firebaseUser.email!);
          if (user == null) {
            // Fallback to local storage if not found in Firestore
            await _loadUserFromLocalStorage(firebaseUser.email!);
            user = _currentUser;
          } else {
            _currentUser = user;
            _isAdmin = user.type == UserType.admin;
          }

          // If still no user data found, create a basic user object
          if (_currentUser == null) {
            _currentUser = User(
              username: firebaseUser.email!,
              password: '',
              points: 0.0,
              type: UserType.user,
              name: null, // Set to null instead of empty string
              department: null,
              course: null,
              idNumber: null,
            );
          }
        } catch (e) {
          print('Error in auth state listener: $e');
          // Create a basic user object if everything fails
          _currentUser = User(
            username: firebaseUser.email!,
            password: '',
            points: 0.0,
            type: UserType.user,
            name: null, // Set to null instead of empty string
            department: null,
            course: null,
            idNumber: null,
          );
        }
      } else {
        _currentUser = null;
        _isAdmin = false;
      }
      onUserChanged(_currentUser);
    });
  }

  static Future<User?> _loadUserFromLocalStorage(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersString = prefs.getString(_usersKey);

      if (usersString != null) {
        final usersMap = jsonDecode(usersString) as Map<String, dynamic>;
        final userData = usersMap[email];

        if (userData != null) {
          _currentUser = User.fromJson(userData);
          _isAdmin = _currentUser!.type == UserType.admin;
          return _currentUser;
        }
      }

      // If user not found in local storage, create a basic user object
      _currentUser = User(
        username: email,
        password: '',
        points: 0.0,
        type: UserType.user,
        name: null, // Set to null instead of empty string
        department: null,
        course: null,
        idNumber: null,
      );
      return _currentUser;
    } catch (e) {
      print('Error loading user from local storage: $e');
      return null;
    }
  }

  static Future<void> _saveUsersToLocalStorage(Map<String, User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersMap = users.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_usersKey, jsonEncode(usersMap));
    } catch (e) {
      print('Error saving users to local storage: $e');
    }
  }

  static Future<Map<String, User>> _loadUsersFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersString = prefs.getString(_usersKey);

      if (usersString != null) {
        final usersMap = jsonDecode(usersString) as Map<String, dynamic>;
        return usersMap.map(
          (key, value) =>
              MapEntry(key, User.fromJson(value as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      print('Error loading users from local storage: $e');
    }
    return {};
  }

  static Future<bool> login(String email, String password) async {
    try {
      // Check admin login first
      if (email == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        _currentUser = User(
          username: email,
          password: password,
          points: 0.0,
          type: UserType.admin,
        );
        _isAdmin = true;
        return true;
      }

      // Check staff login
      if (email == AppConstants.staffUsername &&
          password == AppConstants.staffPassword) {
        _currentUser = User(
          username: email,
          password: password,
          points: 0.0,
          type: UserType.staff,
        );
        _isAdmin = false; // Staff is not admin
        return true;
      }

      // Regular user login with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Load additional user data from Firestore first, then fallback to local storage
        User? user = await _loadUserFromFirestore(email);
        if (user == null) {
          // Fallback to local storage if not found in Firestore
          await _loadUserFromLocalStorage(email);
          user = _currentUser;
        } else {
          _currentUser = user;
          _isAdmin = user.type == UserType.admin;
        }

        // Load profile picture from local storage if not in Firestore
        if (_currentUser != null && _currentUser!.profilePicture == null) {
          final profilePicture = await StorageService.loadProfilePicture(email);
          if (profilePicture != null) {
            _currentUser = _currentUser!.copyWith(
              profilePicture: profilePicture,
            );
          }
        }
        print('Login successful for user: $email');
        return true;
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('user-not-found')) {
        print('Login error: No user found with this email');
      } else if (e.toString().contains('wrong-password')) {
        print('Login error: Incorrect password');
      } else if (e.toString().contains('invalid-email')) {
        print('Login error: Invalid email format');
      } else if (e.toString().contains('user-disabled')) {
        print('Login error: User account has been disabled');
      } else if (e.toString().contains('too-many-requests')) {
        print('Login error: Too many failed attempts. Please try again later');
      }
      return false;
    }
  }

  static Future<bool> register(
    String email,
    String password, {
    String? name,
    String? department,
    String? course,
    String? idNumber,
  }) async {
    try {
      // Prevent admin account registration
      if (email == AppConstants.adminUsername) {
        print('Registration error: Cannot register admin account');
        return false;
      }

      // Validate input parameters
      if (email.isEmpty || password.isEmpty) {
        print('Registration error: Email and password are required');
        return false;
      }

      if (password.length < 6) {
        print('Registration error: Password should be at least 6 characters');
        return false;
      }

      // Check if user already exists in Firebase Auth first
      try {
        final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
        if (signInMethods.isNotEmpty) {
          print('Registration error: Email already exists in Firebase Auth');
          return false;
        }
      } catch (e) {
        print('Error checking existing auth user: $e');
        // If we get a network error, try to continue with registration
        // but we'll catch the duplicate email error during user creation
        if (e.toString().contains('network') ||
            e.toString().contains('offline')) {
          print('Network error detected, continuing with registration attempt');
        } else {
          // For other errors, we might want to fail gracefully
          print('Auth check failed, but continuing with registration');
        }
      }

      // Check if user already exists in local storage
      final existingUsers = await _loadUsersFromLocalStorage();
      if (existingUsers.containsKey(email)) {
        print('Registration error: User already exists in local storage');
        return false;
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Store additional user data in both Firestore and local storage
        final newUser = User(
          username: email,
          password: password,
          points: 0.0,
          type: UserType.user,
          name: name,
          department: department,
          course: course,
          idNumber: idNumber,
        );

        // Save user to Firestore first
        try {
          await saveUserToFirestore(newUser);
          print('User data successfully stored in Firestore');
        } catch (firestoreError) {
          print(
            'Failed to save to Firestore, falling back to local storage only: $firestoreError',
          );
        }

        // Save user to local storage as backup
        existingUsers[email] = newUser;
        await _saveUsersToLocalStorage(existingUsers);
        print('User data successfully stored in local storage');

        // Automatically sign in the user after successful registration
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('Auto sign-in successful after registration');
        } catch (signInError) {
          print('Auto sign-in failed after registration: $signInError');
          // Registration was successful but auto sign-in failed
          // User will need to manually sign in, but we still return true for registration
        }

        _currentUser = newUser;
        _isAdmin = false;
        print('Registration successful for user: $email');
        return true;
      }

      print('Registration error: User credential is null');
      return false;
    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('email-already-in-use')) {
        print('Registration error: Email is already in use');
      } else if (e.toString().contains('weak-password')) {
        print('Registration error: Password is too weak');
      } else if (e.toString().contains('invalid-email')) {
        print('Registration error: Invalid email format');
      } else if (e.toString().contains('network-request-failed')) {
        print('Registration error: Network connection failed');
      } else if (e.toString().contains('too-many-requests')) {
        print(
          'Registration error: Too many failed attempts. Please try again later.',
        );
      }
      return false;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _isAdmin = false;
    // Note: We'll set the logout state in the app state from the calling code
  }

  static Future<bool> updateProfile(
    String newEmail,
    String? newPassword, {
    String? name,
    String? department,
    String? course,
    List<String>? simNumbers,
  }) async {
    try {
      if (_currentUser == null) return false;

      // Don't allow changing admin email
      if (_currentUser!.username == AppConstants.adminUsername &&
          newEmail != AppConstants.adminUsername) {
        return false;
      }

      // Check if new email already exists (and it's not the current user)
      if (newEmail != _currentUser!.username) {
        final existingUsers = await _loadUsersFromLocalStorage();
        if (existingUsers.containsKey(newEmail) &&
            newEmail != _currentUser!.username) {
          return false;
        }
      }

      // Update Firebase Auth email if changed
      if (newEmail != _currentUser!.username && _auth.currentUser != null) {
        await _auth.currentUser!.updateEmail(newEmail);
      }

      // Update password if provided
      if (newPassword != null &&
          newPassword.isNotEmpty &&
          _auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      }

      // Update user data in both Firestore and local storage
      // Preserve points when updating profile
      final updatedUser = _currentUser!.copyWith(
        username: newEmail,
        password: newPassword ?? _currentUser!.password,
        name: name,
        department: department,
        course: course,
        simNumbers: simNumbers,
        points: _currentUser!.points, // Preserve points
      );

      // Save to Firestore first
      try {
        await saveUserToFirestore(updatedUser);
        print('Profile data successfully updated in Firestore');
      } catch (firestoreError) {
        print(
          'Failed to save to Firestore, falling back to local storage only: $firestoreError',
        );
      }

      // Update local storage data
      final existingUsers = await _loadUsersFromLocalStorage();

      // Remove old email entry and add new one if email changed
      if (newEmail != _currentUser!.username) {
        existingUsers.remove(_currentUser!.username);
        existingUsers[newEmail] = updatedUser;
      } else {
        existingUsers[newEmail] = updatedUser;
      }

      await _saveUsersToLocalStorage(existingUsers);
      print('Profile data successfully updated in local storage');

      // Update current user object
      _currentUser = updatedUser;

      return true;
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }

  static Future<void> addPoints(double points) async {
    if (_currentUser == null) return;

    try {
      final newPoints = _currentUser!.points + points;
      final updatedUser = _currentUser!.copyWith(points: newPoints);

      // Save to Firestore first
      try {
        await saveUserToFirestore(updatedUser);
        print('Points successfully updated in Firestore');
      } catch (firestoreError) {
        print(
          'Failed to save to Firestore, falling back to local storage only: $firestoreError',
        );
      }

      // Update points in local storage
      final existingUsers = await _loadUsersFromLocalStorage();
      existingUsers[_currentUser!.username] = updatedUser;
      await _saveUsersToLocalStorage(existingUsers);

      _currentUser = updatedUser;
      print('Points successfully updated in local storage');

      // Notify listeners that user data has changed
      if (_onUserChanged != null) {
        _onUserChanged!(_currentUser);
      }

      // Show points notification
      NewHomeScreen.handlePointsNotification(points);

      // Update reward progress (assuming 1 point = 1 trash disposal)
      // You can adjust this ratio as needed
      await RewardService.updateProgress(points);
    } catch (e) {
      print('Add points error: $e');
    }
  }

  // Firestore methods for user data management
  // Saves complete user data including points to Firestore
  static Future<void> saveUserToFirestore(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.username)
          .set(user.toJson()); // Save complete user data including points
      print('User data (including ${user.points} points) saved to Firestore: ${user.username}');
    } catch (e) {
      print('Error saving user to Firestore: $e');
      throw e;
    }
  }

  static Future<User?> _loadUserFromFirestore(String email) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(email)
          .get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error loading user from Firestore: $e');
      return null;
    }
  }

  static Future<bool> _userExistsInFirestore(String email) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(email)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      print('Error checking user existence in Firestore: $e');
      return false;
    }
  }

  // Helper method to get current Firebase user
  static firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // Profile picture management methods
  static Future<bool> updateProfilePicture(String base64Image) async {
    try {
      if (_currentUser == null) return false;

      // Update user data in both Firestore and local storage
      final updatedUser = _currentUser!.copyWith(profilePicture: base64Image);

      // Save to Firestore first
      try {
        await saveUserToFirestore(updatedUser);
        print('Profile picture successfully updated in Firestore');
      } catch (firestoreError) {
        print(
          'Failed to save to Firestore, falling back to local storage only: $firestoreError',
        );
      }

      // Update local storage data
      final existingUsers = await _loadUsersFromLocalStorage();
      existingUsers[_currentUser!.username] = updatedUser;
      await _saveUsersToLocalStorage(existingUsers);
      print('Profile picture successfully updated in local storage');

      // Also save to StorageService for backward compatibility
      try {
        await StorageService.saveProfilePicture(_currentUser!.username, base64Image);
        print('Profile picture successfully updated in StorageService');
      } catch (e) {
        print('Failed to save to StorageService: $e');
      }

      // Update current user object
      _currentUser = updatedUser;

      // Notify listeners so Provider/AppState gets the latest user data.
      if (_onUserChanged != null) {
        _onUserChanged!(_currentUser);
      }

      return true;
    } catch (e) {
      print('Profile picture update error: $e');
      return false;
    }
  }

  static Future<void> removeProfilePicture() async {
    try {
      if (_currentUser == null) return;

      // Update user data in both Firestore and local storage
      final updatedUser = _currentUser!.copyWith(profilePicture: null);

      // Save to Firestore first
      try {
        await saveUserToFirestore(updatedUser);
        print('Profile picture successfully removed from Firestore');
      } catch (firestoreError) {
        print(
          'Failed to save to Firestore, falling back to local storage only: $firestoreError',
        );
      }

      // Update local storage data
      final existingUsers = await _loadUsersFromLocalStorage();
      existingUsers[_currentUser!.username] = updatedUser;
      await _saveUsersToLocalStorage(existingUsers);
      print('Profile picture successfully removed from local storage');

      // Also remove from StorageService for backward compatibility
      try {
        await StorageService.removeProfilePicture(_currentUser!.username);
        print('Profile picture successfully removed from StorageService');
      } catch (e) {
        print('Failed to remove from StorageService: $e');
      }

      // Update current user object
      _currentUser = updatedUser;

      // Notify listeners so Provider/AppState gets the latest user data.
      if (_onUserChanged != null) {
        _onUserChanged!(_currentUser);
      }
    } catch (e) {
      print('Profile picture removal error: $e');
    }
  }

  // Method to get all users from Firestore
  static Stream<List<User>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User.fromJson(data);
      }).toList();
    });
  }

  // Method to delete a user from Firestore
  static Future<void> deleteUser(String username) async {
    try {
      await _firestore.collection(_usersCollection).doc(username).delete();
      print('User deleted from Firestore: $username');
    } catch (e) {
      print('Error deleting user from Firestore: $e');
      throw e;
    }
  }

  // Method to get the total number of users from Firestore
  static Future<int> getUserCount() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting user count from Firestore: $e');
      return 0;
    }
  }

  // Method to get the total number of staff users from Firestore
  static Future<int> getStaffCount() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('type', isEqualTo: 'staff')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting staff count from Firestore: $e');
      return 0;
    }
  }
}
