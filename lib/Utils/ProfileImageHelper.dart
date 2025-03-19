import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileImageHelper {
  // In-memory cache for profile images
  static final Map<String, Uint8List> _imageCache = {};

  // Get current user's UID
  static String _getCurrentUserUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  // Get profile picture from Firebase
  static Future<String?> getProfilePictureBase64([String? uid]) async {
    uid ??= _getCurrentUserUid();
    try {
      DatabaseReference databaseRef = FirebaseDatabase.instance.ref('users/$uid/profile_data');
      DataSnapshot snapshot = await databaseRef.child('profile_picture').get();
      if (snapshot.exists) {
        return snapshot.value as String?;
      }
    } catch (e) {
      throw Exception('Error retrieving profile picture: $e');
    }
    return null;
  }

  // Get decoded profile image bytes with caching
  static Future<Uint8List?> getProfileImageBytes([String? uid]) async {
    uid ??= _getCurrentUserUid();

    // Check cache first
    if (_imageCache.containsKey(uid)) {
      return _imageCache[uid];
    }

    try {
      String? base64String = await getProfilePictureBase64(uid);
      if (base64String != null && base64String.isNotEmpty) {
        Uint8List imageBytes = base64Decode(base64String);
        // Store in cache
        _imageCache[uid] = imageBytes;
        return imageBytes;
      }
    } catch (e) {
      print('Error decoding profile picture: $e');
    }

    return null;
  }

  // Clear cache for current user (useful after profile update)
  static void clearCurrentUserCache() {
    String uid = _getCurrentUserUid();
    clearUserCache(uid);
  }

  // Clear cache for a specific user
  static void clearUserCache(String uid) {
    if (_imageCache.containsKey(uid)) {
      _imageCache.remove(uid);
    }
  }

  // Clear entire cache
  static void clearCache() {
    _imageCache.clear();
  }

  // Get profile image widget with caching
  static Future<Widget> getProfileImage({
    String? uid,
    required BuildContext context,
    double size = 35.0,
    String defaultImagePath = 'assets/icon/icon.png',
    BoxFit fit = BoxFit.cover,
  }) async {
    uid ??= _getCurrentUserUid();

    try {
      Uint8List? imageBytes = await getProfileImageBytes(uid);
      if (imageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            imageBytes,
            width: size,
            height: size,
            fit: fit,
          ),
        );
      }
    } catch (e) {
      print('Error creating profile picture widget: $e');
    }

    // Fallback to default image
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        defaultImagePath,
        width: size,
        height: size,
        fit: fit,
      ),
    );
  }

  // Get profile image widget with loading indicator
  static Widget getProfileImageWithLoading({
    String? uid,
    required BuildContext context,
    double size = 35.0,
    String defaultImagePath = 'assets/icon/icon.png',
    BoxFit fit = BoxFit.cover,
  }) {
    uid ??= _getCurrentUserUid();

    return FutureBuilder<Widget>(
      future: getProfileImage(
        uid: uid,
        context: context,
        size: size,
        defaultImagePath: defaultImagePath,
        fit: fit,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.2),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.asset(
              defaultImagePath,
              width: size,
              height: size,
              fit: fit,
            ),
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}