import 'package:flutter/material.dart';

/// A curated, stable palette users can pick for an account or category.
///
/// We persist [AppColorKey.name] (not a raw ARGB int) to Firestore, so the
/// palette can be re-themed later without a data migration.
enum AppColorKey {
  emerald(Color(0xFF0F9D6B)),
  red(Colors.redAccent),
  orange(Colors.orangeAccent),
  amber(Color(0xFFFFB300)),
  green(Colors.green),
  teal(Colors.teal),
  cyan(Colors.cyan),
  blue(Colors.blue),
  indigo(Colors.indigo),
  purple(Colors.purple),
  pink(Colors.pinkAccent),
  brown(Colors.brown),
  blueGrey(Colors.blueGrey),
  grey(Colors.grey);

  const AppColorKey(this.color);

  final Color color;
}
