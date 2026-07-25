import '../../../../core/constants/app_icon_key.dart';

/// The five account types Cashly supports. Each has a sensible default
/// icon, but the user can always override it via the icon picker.
enum AccountType {
  cash(label: 'Cash', defaultIcon: AppIconKey.cash),
  wallet(label: 'Wallet', defaultIcon: AppIconKey.wallet),
  bank(label: 'Bank', defaultIcon: AppIconKey.bank),
  creditCard(label: 'Credit Card', defaultIcon: AppIconKey.creditCard),
  savings(label: 'Savings', defaultIcon: AppIconKey.savings);

  const AccountType({required this.label, required this.defaultIcon});

  final String label;
  final AppIconKey defaultIcon;
}
