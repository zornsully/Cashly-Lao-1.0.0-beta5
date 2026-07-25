/// Shared sizing constants for chart legends, referenced by every chart
/// widget (Reports' pie/trend charts, Dashboard's spending bar) instead of
/// each one picking its own legend-dot size.
abstract final class AppChartStyle {
  /// Diameter of the small color-identity dot used in every chart legend.
  static const double legendDotSize = 10;
}
