import '../entities/financial_insight.dart';

/// Contract for Cashly's financial assistant.
///
/// The current implementation is fully on-device and rule based. A future
/// provider-backed LLM can implement this interface and receive only the
/// aggregated [FinancialInsightSnapshot] it needs.
abstract interface class FinancialInsightEngine {
  Future<FinancialInsight> analyze(FinancialInsightSnapshot snapshot);
}
