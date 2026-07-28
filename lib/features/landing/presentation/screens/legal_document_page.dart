import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/cashly_logo_mark.dart';

/// A readable, public legal-information page shown outside the signed-in app.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage.privacy({super.key})
    : _document = _LegalDocument.privacy;

  const LegalDocumentPage.terms({super.key}) : _document = _LegalDocument.terms;

  final _LegalDocument _document;

  @override
  Widget build(BuildContext context) {
    final content = switch (_document) {
      _LegalDocument.privacy => _privacyContent,
      _LegalDocument.terms => _termsContent,
    };

    return Scaffold(
      backgroundColor: _LegalColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 56),
                      child: Row(
                        children: [
                          const CashlyLogoMark(size: 34),
                          const SizedBox(width: 10),
                          const Text(
                            'Cashly Lao',
                            style: TextStyle(
                              color: _LegalColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context.go(AppRoutes.landing),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 17,
                            ),
                            label: const Text('Back to home'),
                            style: TextButton.styleFrom(
                              foregroundColor: _LegalColors.green,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Text(
                      _document == _LegalDocument.privacy
                          ? 'Privacy Policy'
                          : 'Terms of Service',
                      style: const TextStyle(
                        color: _LegalColors.ink,
                        fontSize: 44,
                        height: 1.05,
                        letterSpacing: -1.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 34),
                      child: Text(
                        _document == _LegalDocument.privacy
                            ? 'Last updated July 25, 2026'
                            : 'Cashly Lao early-release terms',
                        style: const TextStyle(
                          color: _LegalColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: content.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 28),
                    itemBuilder: (context, index) {
                      final section = content[index];
                      return _LegalSection(section: section);
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 72)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.section});

  final _LegalSectionContent section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _LegalColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: _LegalColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: const TextStyle(
              color: _LegalColors.muted,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LegalDocument { privacy, terms }

class _LegalSectionContent {
  const _LegalSectionContent(this.title, this.body);

  final String title;
  final String body;
}

const _privacyContent = [
  _LegalSectionContent(
    'Our commitment',
    'Cashly Lao is a personal finance app for tracking income, expenses, accounts, budgets, and category spending. We respect the privacy of the information you choose to enter.',
  ),
  _LegalSectionContent(
    'Information we handle',
    'To provide the app, we handle account details such as your email address, display name, profile photo when supplied by Google, and a Firebase user ID. We also store the financial records you enter, including accounts, transactions, categories, and budgets.',
  ),
  _LegalSectionContent(
    'How your information is used',
    'Your information powers core app features, secure sign-in, cloud sync across your own devices, and customer support. Crash reports and limited, non-financial usage analytics help us diagnose technical problems and improve the product.',
  ),
  _LegalSectionContent(
    'Storage and sharing',
    'Cashly Lao uses Google Firebase Authentication and Cloud Firestore to provide sign-in and cloud storage. We do not sell or rent your personal information. Data is shared only with the services needed to run Cashly, when you choose Google Sign-In, or when required by law.',
  ),
  _LegalSectionContent(
    'Security and control',
    'We use Firebase Authentication, server-enforced Firestore security rules, and encrypted HTTPS connections. No online service can guarantee absolute security, but we take reasonable steps to protect your information. You can update your information in the app or permanently delete your account and associated financial data from Profile > Delete account.',
  ),
  _LegalSectionContent(
    'Contact',
    'For a privacy question or help deleting your data, contact Zornsully Manijun at contact@cashlylao.com or +856 20 59146361 in Lao PDR.',
  ),
];

const _termsContent = [
  _LegalSectionContent(
    'Early-release availability',
    'Cashly Lao is an early-release personal finance app. It is provided to help you organize your own money records, and features may change as the app continues to improve.',
  ),
  _LegalSectionContent(
    'Your information',
    'You are responsible for the accuracy of the information you enter and for keeping your sign-in credentials private. Please use the app only for lawful personal finance tracking.',
  ),
  _LegalSectionContent(
    'Not financial advice',
    'Cashly Lao presents the financial information you enter. Its charts, scores, suggestions, and insights are informational tools, not professional financial, legal, tax, or investment advice.',
  ),
  _LegalSectionContent(
    'Questions about use',
    'For help with Cashly Lao or questions about these early-release terms, please contact contact@cashlylao.com.',
  ),
];

abstract final class _LegalColors {
  static const canvas = Color(0xFFFBFCFB);
  static const ink = Color(0xFF17211B);
  static const muted = Color(0xFF66736A);
  static const green = Color(0xFF2E7D32);
  static const line = Color(0xFFE2E9E3);
}
