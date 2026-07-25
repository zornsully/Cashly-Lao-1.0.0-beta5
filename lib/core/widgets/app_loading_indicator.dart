import 'package:flutter/material.dart';

/// Full-body centered loading indicator used while a screen's primary data
/// is still resolving (auth state, first Firestore fetch, ...).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
