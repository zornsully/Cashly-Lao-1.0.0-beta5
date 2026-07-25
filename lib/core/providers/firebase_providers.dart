import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton Firebase SDK instances, exposed through Riverpod so every
/// datasource depends on these providers instead of touching
/// `FirebaseAuth.instance` / `FirebaseFirestore.instance` directly. This is
/// what makes datasources mockable in tests.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Accessed only through `logAnalyticsEvent` (`core/utils/analytics_logger.dart`),
/// never read directly at a call site — that helper is what makes logging
/// safe to call from code paths tests exercise without a Firebase app.
final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});
