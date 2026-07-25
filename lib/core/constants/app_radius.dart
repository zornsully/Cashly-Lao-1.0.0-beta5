/// Shared corner-radius scale so every card, button, input, and sheet
/// rounds consistently instead of hand-picked values scattered per widget.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  /// Fully rounded (pills, circular avatars via `BorderRadius.circular`).
  static const double full = 999;
}
