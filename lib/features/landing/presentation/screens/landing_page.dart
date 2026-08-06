import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/cashly_logo_mark.dart';
import '../../data/services/hosted_release_manifest_service.dart';
import '../../domain/entities/release_manifest.dart';
import '../../domain/services/release_manifest_service.dart';

/// Cashly Lao's public, web-first product page.
///
/// It intentionally lives outside the authenticated app shell: visitors can
/// learn about Cashly and download the Android release without an account.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key, this.releaseManifestService})
    : _page = _PublicSitePage.home;

  const LandingPage.features({super.key})
    : _page = _PublicSitePage.features,
      releaseManifestService = null;

  const LandingPage.screenshots({super.key})
    : _page = _PublicSitePage.screenshots,
      releaseManifestService = null;

  const LandingPage.download({super.key, this.releaseManifestService})
    : _page = _PublicSitePage.download;

  const LandingPage.privacy({super.key})
    : _page = _PublicSitePage.privacy,
      releaseManifestService = null;

  /// Allows focused UI tests and a future release provider to supply metadata
  /// without coupling the landing page to a particular delivery channel.
  final ReleaseManifestService? releaseManifestService;
  final _PublicSitePage _page;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static final Uri _contactUri = Uri(
    scheme: 'mailto',
    path: 'contact@cashlylao.com',
    queryParameters: const {'subject': 'Cashly Lao support'},
  );

  late final ReleaseManifestService _releaseManifestService;
  late Future<ReleaseManifest> _releaseManifestFuture;

  @override
  void initState() {
    super.initState();
    _releaseManifestService =
        widget.releaseManifestService ?? HostedReleaseManifestService();
    _releaseManifestFuture = _releaseManifestService.loadLatest();
  }

  void _retryReleaseManifest() {
    setState(() {
      _releaseManifestFuture = _releaseManifestService.loadLatest();
    });
  }

  Future<void> _openRelease(PlatformRelease release) async {
    final downloadUri = release.downloadUrl;
    if (!release.isAvailable || downloadUri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(release.availabilityMessage)));
      return;
    }

    final opened = await launchUrl(
      downloadUri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start the ${release.displayName} download.'),
        ),
      );
    }
  }

  Future<void> _contact() async {
    final opened = await launchUrl(_contactUri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please email contact@cashlylao.com.')),
      );
    }
  }

  void _navigate(_PublicSitePage page) {
    context.go(page.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LandingColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _LandingNavigation(
              currentPage: widget._page,
              onNavigate: _navigate,
              onOpenApp: () => context.go(AppRoutes.dashboard),
            ),
            _buildPage(),
            _LandingFooter(
              onPrivacy: () => context.go(AppRoutes.privacy),
              onTerms: () => context.go(AppRoutes.terms),
              onContact: _contact,
              onFeatures: () => context.go(AppRoutes.features),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    if (widget._page == _PublicSitePage.features) {
      return const _LandingShell(
        child: _PublicSiteBody(child: _FeaturesSection()),
      );
    }
    if (widget._page == _PublicSitePage.screenshots) {
      return const _LandingShell(
        child: _PublicSiteBody(child: _ScreenshotsSection()),
      );
    }
    if (widget._page == _PublicSitePage.privacy) {
      return const _LandingShell(
        child: _PublicSiteBody(child: _PrivacyPolicySection()),
      );
    }

    return FutureBuilder<ReleaseManifest>(
      future: _releaseManifestFuture,
      builder: (context, snapshot) {
        final manifest = snapshot.data;
        final isLoading =
            snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasError;
        final errorMessage = snapshot.hasError
            ? _releaseLoadErrorMessage(snapshot.error)
            : null;
        final isDownloadPage = widget._page == _PublicSitePage.download;
        return _LandingShell(
          child: _PublicSiteBody(
            child: isDownloadPage
                ? Column(
                    children: [
                      _ApkDownloadSection(
                        release: manifest?.releaseFor(ReleasePlatform.android),
                        manifest: manifest,
                        isLoading: isLoading,
                        hasLoadError: snapshot.hasError,
                        loadErrorMessage: errorMessage,
                        onOpenRelease: _openRelease,
                        onRetry: _retryReleaseManifest,
                      ),
                      if ((manifest?.history.isNotEmpty ?? false))
                        _VersionHistorySection(history: manifest!.history),
                      const _FaqSection(),
                    ],
                  )
                : Column(
                    children: [
                      _HeroSection(
                        releaseManifest: manifest,
                        isLoading: isLoading,
                        hasLoadError: snapshot.hasError,
                        loadErrorMessage: errorMessage,
                        onOpenRelease: _openRelease,
                        onRetry: _retryReleaseManifest,
                      ),
                      _HomePreviewLinks(onNavigate: _navigate),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

String _releaseLoadErrorMessage(Object? error) {
  if (error is ReleaseManifestFetchException) return error.message;
  return 'Release details are temporarily unavailable.';
}

enum _PublicSitePage { home, features, screenshots, download, privacy }

extension on _PublicSitePage {
  String get path => switch (this) {
    _PublicSitePage.home => AppRoutes.landing,
    _PublicSitePage.features => AppRoutes.features,
    _PublicSitePage.screenshots => AppRoutes.screenshots,
    _PublicSitePage.download => AppRoutes.download,
    _PublicSitePage.privacy => AppRoutes.privacy,
  };
}

abstract final class _LandingColors {
  static const canvas = Color(0xFFFBFCFB);
  static const ink = Color(0xFF17211B);
  static const mutedInk = Color(0xFF66736A);
  static const green = Color(0xFF2E7D32);
  static const greenDark = Color(0xFF205C26);
  static const greenTint = Color(0xFFEAF5EC);
  static const mint = Color(0xFFCFEAD3);
  static const line = Color(0xFFE2E9E3);
}

class _LandingShell extends StatelessWidget {
  const _LandingShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _LandingNavigation extends StatelessWidget {
  const _LandingNavigation({
    required this.currentPage,
    required this.onNavigate,
    required this.onOpenApp,
  });

  final _PublicSitePage currentPage;
  final ValueChanged<_PublicSitePage> onNavigate;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    return _LandingShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final narrow = constraints.maxWidth < 460;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _LandingColors.line),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF102015).withValues(alpha: .05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const CashlyLogoMark(size: 34),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Cashly Lao',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _LandingColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!compact) ...[
                      _NavTextButton(
                        label: 'Home',
                        active: currentPage == _PublicSitePage.home,
                        onPressed: () => onNavigate(_PublicSitePage.home),
                      ),
                      _NavTextButton(
                        label: 'Features',
                        active: currentPage == _PublicSitePage.features,
                        onPressed: () => onNavigate(_PublicSitePage.features),
                      ),
                      _NavTextButton(
                        label: 'Screenshots',
                        active: currentPage == _PublicSitePage.screenshots,
                        onPressed: () =>
                            onNavigate(_PublicSitePage.screenshots),
                      ),
                      _NavTextButton(
                        label: 'Download',
                        active: currentPage == _PublicSitePage.download,
                        onPressed: () => onNavigate(_PublicSitePage.download),
                      ),
                      _NavTextButton(
                        label: 'Privacy Policy',
                        active: currentPage == _PublicSitePage.privacy,
                        onPressed: () => onNavigate(_PublicSitePage.privacy),
                      ),
                      const SizedBox(width: 6),
                    ] else
                      PopupMenuButton<_PublicSitePage>(
                        tooltip: 'Open navigation',
                        icon: const Icon(Icons.menu_rounded),
                        onSelected: onNavigate,
                        itemBuilder: (context) => [
                          CheckedPopupMenuItem(
                            value: _PublicSitePage.home,
                            checked: currentPage == _PublicSitePage.home,
                            child: Text('Home'),
                          ),
                          CheckedPopupMenuItem(
                            value: _PublicSitePage.features,
                            checked: currentPage == _PublicSitePage.features,
                            child: Text('Features'),
                          ),
                          CheckedPopupMenuItem(
                            value: _PublicSitePage.screenshots,
                            checked: currentPage == _PublicSitePage.screenshots,
                            child: Text('Screenshots'),
                          ),
                          CheckedPopupMenuItem(
                            value: _PublicSitePage.download,
                            checked: currentPage == _PublicSitePage.download,
                            child: Text('Download'),
                          ),
                          CheckedPopupMenuItem(
                            value: _PublicSitePage.privacy,
                            checked: currentPage == _PublicSitePage.privacy,
                            child: Text('Privacy Policy'),
                          ),
                        ],
                      ),
                    if (narrow)
                      Tooltip(
                        message: 'Open app',
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: FilledButton(
                            onPressed: onOpenApp,
                            style: FilledButton.styleFrom(
                              backgroundColor: _LandingColors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: onOpenApp,
                        style: _primaryButtonStyle(compact: true),
                        child: const Text('Open app'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active
            ? _LandingColors.greenDark
            : _LandingColors.mutedInk,
        backgroundColor: active ? _LandingColors.greenTint : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

/// Gives every public page the same breathing room while allowing the home
/// page to remain intentionally short.
class _PublicSiteBody extends StatelessWidget {
  const _PublicSiteBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _FadeInUp(delay: const Duration(milliseconds: 40), child: child);
}

class _HomePreviewLinks extends StatelessWidget {
  const _HomePreviewLinks({required this.onNavigate});

  final ValueChanged<_PublicSitePage> onNavigate;

  @override
  Widget build(BuildContext context) {
    const links = [
      (
        page: _PublicSitePage.features,
        icon: Icons.auto_awesome_rounded,
        title: 'Explore features',
        text: 'See the tools that keep your money organized.',
      ),
      (
        page: _PublicSitePage.screenshots,
        icon: Icons.photo_library_outlined,
        title: 'View screenshots',
        text: 'Preview the calm, focused app experience.',
      ),
      (
        page: _PublicSitePage.download,
        icon: Icons.download_rounded,
        title: 'Get Cashly Lao',
        text: 'Find the latest verified release details.',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 820 ? 3 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 18,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 3.2 : 1.18,
            children: links
                .map(
                  (link) => _HomePreviewCard(
                    icon: link.icon,
                    title: link.title,
                    text: link.text,
                    onTap: () => onNavigate(link.page),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _HomePreviewCard extends StatelessWidget {
  const _HomePreviewCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          border: Border.all(color: _LandingColors.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _LandingColors.green, size: 27),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: _LandingColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              text,
              style: const TextStyle(
                color: _LandingColors.mutedInk,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrivacyPolicySection extends StatelessWidget {
  const _PrivacyPolicySection();

  @override
  Widget build(BuildContext context) => _LandingSection(
    eyebrow: 'Privacy policy',
    title: 'Your financial life is private by design.',
    description:
        'Effective August 2026. This policy explains how Cashly Lao handles the information needed to provide the app.',
    child: const Column(
      children: [
        _PolicyCard(
          title: 'Information we use',
          text:
              'Cashly Lao stores the account, transaction, budget, category, and profile information you choose to enter so the app can provide personal finance features and secure cloud sync.',
        ),
        _PolicyCard(
          title: 'How we use it',
          text:
              'Your information is used only to run the app, secure your account, synchronize your data across your devices, provide support, and improve reliability. We do not sell or rent your personal information.',
        ),
        _PolicyCard(
          title: 'Your choices',
          text:
              'You can edit your finance records in the app and request account deletion. For privacy questions or help deleting data, email contact@cashlylao.com.',
        ),
      ],
    ),
  );
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _LandingColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _LandingColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            color: _LandingColors.mutedInk,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.releaseManifest,
    required this.isLoading,
    required this.hasLoadError,
    required this.loadErrorMessage,
    required this.onOpenRelease,
    required this.onRetry,
  });

  final ReleaseManifest? releaseManifest;
  final bool isLoading;
  final bool hasLoadError;
  final String? loadErrorMessage;
  final ValueChanged<PlatformRelease> onOpenRelease;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        final content = _HeroCopy(
          releaseManifest: releaseManifest,
          isLoading: isLoading,
          hasLoadError: hasLoadError,
          loadErrorMessage: loadErrorMessage,
          onOpenRelease: onOpenRelease,
          onRetry: onRetry,
          centered: !isDesktop,
        );
        final mockup = const _PhoneMockup();

        return Padding(
          padding: EdgeInsets.only(
            top: isDesktop ? 72 : 48,
            bottom: isDesktop ? 120 : 88,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: content),
                    const SizedBox(width: 64),
                    const Expanded(
                      flex: 8,
                      child: Center(child: _PhoneMockup()),
                    ),
                  ],
                )
              : Column(children: [content, const SizedBox(height: 48), mockup]),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.releaseManifest,
    required this.isLoading,
    required this.hasLoadError,
    required this.loadErrorMessage,
    required this.onOpenRelease,
    required this.onRetry,
    required this.centered,
  });

  final ReleaseManifest? releaseManifest;
  final bool isLoading;
  final bool hasLoadError;
  final String? loadErrorMessage;
  final ValueChanged<PlatformRelease> onOpenRelease;
  final VoidCallback onRetry;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _LandingColors.greenTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Built for everyday life in Laos',
            style: TextStyle(
              color: _LandingColors.greenDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Take Control\nof Your Money.',
          textAlign: textAlign,
          style: TextStyle(
            color: _LandingColors.ink,
            fontSize: centered ? 46 : 64,
            height: .98,
            letterSpacing: -2.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Cashly Lao helps you track expenses, manage income, and understand your finances with a simple, beautiful experience.',
            textAlign: textAlign,
            style: const TextStyle(
              color: _LandingColors.mutedInk,
              fontSize: 18,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _HeroPlatformDownloads(
          centered: centered,
          releaseManifest: releaseManifest,
          isLoading: isLoading,
          hasLoadError: hasLoadError,
          loadErrorMessage: loadErrorMessage,
          onOpenRelease: onOpenRelease,
          onRetry: onRetry,
        ),
        const SizedBox(height: 22),
        const Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _TrustPoint(
              icon: Icons.lock_outline_rounded,
              label: 'Private by design',
            ),
            _TrustPoint(
              icon: Icons.cloud_done_outlined,
              label: 'Secure cloud sync',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPlatformDownloads extends StatelessWidget {
  const _HeroPlatformDownloads({
    required this.centered,
    required this.releaseManifest,
    required this.isLoading,
    required this.hasLoadError,
    required this.loadErrorMessage,
    required this.onOpenRelease,
    required this.onRetry,
  });

  final bool centered;
  final ReleaseManifest? releaseManifest;
  final bool isLoading;
  final bool hasLoadError;
  final String? loadErrorMessage;
  final ValueChanged<PlatformRelease> onOpenRelease;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cards = ReleasePlatform.values
        .map((platform) {
          final release = releaseManifest?.releaseFor(platform);
          final latestStableRelease = releaseManifest?.latestStableReleaseFor(
            platform,
          );
          final metadataLabel =
              latestStableRelease?.versionLabel ??
              release?.statusLabel ??
              (isLoading
                  ? 'Checking availability'
                  : hasLoadError
                  ? 'Release unavailable'
                  : 'Unavailable');
          return _PlatformDownloadCard(
            icon: _platformIcon(platform),
            iconColor: _platformIconColor(platform),
            label: release?.displayName ?? platform.fallbackDisplayName,
            metadataLabel: metadataLabel,
            detailLabel: latestStableRelease?.releaseDateLabel,
            actionLabel: latestStableRelease?.isAvailable == true
                ? latestStableRelease!.actionLabel
                : null,
            statusLabel: release?.statusLabel,
            // A legacy or incomplete manifest can explain availability but
            // never becomes a download action. Only a strict schema-v2,
            // latest-stable entry is eligible to open a public artifact.
            onPressed: latestStableRelease == null
                ? null
                : () => onOpenRelease(latestStableRelease),
          );
        })
        .toList(growable: false);

    return Align(
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useGrid = constraints.maxWidth < 440;

            return Column(
              crossAxisAlignment: centered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'DOWNLOAD',
                  style: const TextStyle(
                    color: _LandingColors.mutedInk,
                    fontSize: 11,
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (useGrid)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.18,
                    children: cards,
                  )
                else
                  SizedBox(
                    height: 128,
                    child: Row(
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          Expanded(child: cards[index]),
                          if (index < cards.length - 1)
                            const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                if (releaseManifest?.isFallback == true) ...[
                  const SizedBox(height: 12),
                  _ReleaseChannelNotice(
                    message: _fallbackReleaseNotice(releaseManifest),
                    onRetry: onRetry,
                    centered: centered,
                  ),
                ] else if (hasLoadError) ...[
                  const SizedBox(height: 12),
                  _ReleaseChannelNotice(
                    message:
                        loadErrorMessage ??
                        'Release details are temporarily unavailable.',
                    onRetry: onRetry,
                    centered: centered,
                    isError: true,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _fallbackReleaseNotice(ReleaseManifest? manifest) {
  return switch (manifest?.source) {
    ReleaseManifestSource.persistentCache =>
      'Showing the last verified release details while the release channel reconnects.',
    ReleaseManifestSource.bundledFallback =>
      'Showing bundled release information. Downloads stay disabled until a current release is verified.',
    _ => 'Release details are temporarily unavailable.',
  };
}

IconData _platformIcon(ReleasePlatform platform) {
  return switch (platform) {
    ReleasePlatform.android => Icons.android_rounded,
    ReleasePlatform.ios => Icons.apple,
    ReleasePlatform.windows => Icons.window_rounded,
    ReleasePlatform.mac => Icons.laptop_mac_rounded,
  };
}

Color _platformIconColor(ReleasePlatform platform) {
  return switch (platform) {
    ReleasePlatform.android || ReleasePlatform.windows => _LandingColors.green,
    ReleasePlatform.ios || ReleasePlatform.mac => _LandingColors.ink,
  };
}

class _PlatformDownloadCard extends StatefulWidget {
  const _PlatformDownloadCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.metadataLabel,
    required this.detailLabel,
    required this.actionLabel,
    required this.statusLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String metadataLabel;
  final String? detailLabel;
  final String? actionLabel;
  final String? statusLabel;
  final VoidCallback? onPressed;

  @override
  State<_PlatformDownloadCard> createState() => _PlatformDownloadCardState();
}

class _PlatformDownloadCardState extends State<_PlatformDownloadCard> {
  var _isHovering = false;

  void _setHovering(bool value) {
    if (_isHovering == value) return;
    setState(() => _isHovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onPressed != null;
    final actionLabel = widget.actionLabel;
    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: isInteractive ? (_) => _setHovering(true) : null,
      onExit: isInteractive ? (_) => _setHovering(false) : null,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        offset: _isHovering ? const Offset(0, -.025) : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isHovering ? _LandingColors.greenTint : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _isHovering ? _LandingColors.mint : _LandingColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: _LandingColors.ink.withValues(
                  alpha: _isHovering ? .10 : .04,
                ),
                blurRadius: _isHovering ? 18 : 12,
                offset: Offset(0, _isHovering ? 8 : 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: widget.statusLabel ?? widget.metadataLabel,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(17),
                child: Semantics(
                  button: true,
                  enabled: isInteractive,
                  label: [
                    widget.label,
                    widget.metadataLabel,
                    ?widget.statusLabel,
                    ?widget.actionLabel,
                  ].join(', '),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 27),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 16,
                          child: Center(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _LandingColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 12,
                          child: Center(
                            child: Text(
                              widget.metadataLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _LandingColors.mutedInk,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 11,
                          child: widget.detailLabel == null
                              ? null
                              : Center(
                                  child: Text(
                                    widget.detailLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _LandingColors.mutedInk,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 12,
                          child: actionLabel == null
                              ? null
                              : Text(
                                  actionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _LandingColors.greenDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseChannelNotice extends StatelessWidget {
  const _ReleaseChannelNotice({
    required this.message,
    required this.onRetry,
    required this.centered,
    this.isError = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool centered;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isError
        ? const Color(0xFF9C3B2A)
        : _LandingColors.greenDark;
    final backgroundColor = isError
        ? const Color(0xFFFFF4F0)
        : _LandingColors.greenTint;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFF0C6BA) : _LandingColors.mint,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: foregroundColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: foregroundColor,
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _LandingColors.green),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: _LandingColors.mutedInk,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 64,
            right: -48,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: _LandingColors.mint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -46,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF5EE),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF17211B),
              borderRadius: BorderRadius.circular(42),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF102015).withValues(alpha: .22),
                  blurRadius: 36,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(33),
              child: AspectRatio(
                aspectRatio: 1344 / 2992,
                child: Image.asset(
                  'store_assets/screenshots/en_dashboard.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            right: -32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF102015).withValues(alpha: .10),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: _LandingColors.green,
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Know your pace',
                    style: TextStyle(
                      color: _LandingColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      eyebrow: 'Everything you need',
      title: 'A calmer way to stay on top of money.',
      description:
          'Cashly keeps the essentials simple, so you spend less time managing data and more time making confident decisions.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 920
              ? 3
              : constraints.maxWidth >= 600
              ? 2
              : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: columns == 1 ? 1.12 : 1.15,
            children: const [
              _FeatureCard(
                icon: Icons.edit_note_rounded,
                title: 'Expense Tracking',
                description: 'Record daily income and expenses easily.',
              ),
              _FeatureCard(
                icon: Icons.auto_graph_rounded,
                title: 'Financial Insights',
                description:
                    'Understand spending patterns using clear charts and reports.',
              ),
              _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Budgets',
                description: 'Create budgets and monitor category limits.',
              ),
              _FeatureCard(
                icon: Icons.account_balance_outlined,
                title: 'Accounts',
                description:
                    'Manage balances across multiple accounts and currencies.',
              ),
              _FeatureCard(
                icon: Icons.savings_outlined,
                title: 'Goals',
                description: 'Create savings goals and monitor progress.',
              ),
              _FeatureCard(
                icon: Icons.verified_user_outlined,
                title: 'Private and Secure',
                description: 'Keep your financial data safe and personal.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _LandingColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102015).withValues(alpha: .04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _LandingColors.greenTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _LandingColors.green, size: 25),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: _LandingColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: _LandingColors.mutedInk,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection();

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      eyebrow: 'Made for clarity',
      title: 'A beautiful view of your everyday finances.',
      description:
          'Every screen is designed to feel focused and familiar - whether you are checking a balance, adding an expense, or planning the month.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1040
              ? 4
              : constraints.maxWidth >= 620
              ? 2
              : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 18,
            mainAxisSpacing: 22,
            childAspectRatio: columns == 1 ? .58 : .47,
            children: const [
              _ScreenshotCard(
                title: 'Dashboard',
                imagePath: 'store_assets/screenshots/en_dashboard.png',
              ),
              _ScreenshotCard(
                title: 'Transactions',
                imagePath: 'store_assets/screenshots/en_transactions.png',
              ),
              _ScreenshotCard(
                title: 'Statistics',
                imagePath: 'store_assets/screenshots/en_reports.png',
              ),
              _ScreenshotCard(
                title: 'Budgets',
                imagePath: 'store_assets/screenshots/en_budget.png',
              ),
              _ScreenshotCard(
                title: 'Accounts',
                imagePath: 'store_assets/screenshots/en_accounts.png',
              ),
              // A dedicated goals capture is added when the screen ships.
              // Reusing the existing budget planning capture keeps the public
              // gallery complete without referencing a non-existent asset.
              _ScreenshotCard(
                title: 'Goals',
                imagePath: 'store_assets/screenshots/en_budget.png',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  const _ScreenshotCard({required this.title, required this.imagePath});

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _LandingColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102015).withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _LandingColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _LandingColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApkDownloadSection extends StatelessWidget {
  const _ApkDownloadSection({
    required this.release,
    required this.manifest,
    required this.isLoading,
    required this.hasLoadError,
    required this.loadErrorMessage,
    required this.onOpenRelease,
    required this.onRetry,
  });

  final PlatformRelease? release;
  final ReleaseManifest? manifest;
  final bool isLoading;
  final bool hasLoadError;
  final String? loadErrorMessage;
  final ValueChanged<PlatformRelease> onOpenRelease;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 128, bottom: 112),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F6B2A), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _LandingColors.green.withValues(alpha: .25),
              blurRadius: 36,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final currentRelease = release;
            final isFallback = manifest?.isFallback == true;
            final isLegacyFallback =
                manifest?.schemaVersion != ReleaseManifest.currentSchemaVersion;
            final latestStableRelease = manifest?.latestStableReleaseFor(
              ReleasePlatform.android,
            );
            // Only ever links to the official GitHub Release page for the
            // verified latest release — never surfaced for a fallback,
            // legacy, or otherwise untrusted manifest.
            final releaseNotesUrl = latestStableRelease != null
                ? manifest?.release?.releaseUrl
                : null;
            final supportingText = currentRelease == null
                ? isLoading
                      ? 'Checking the latest release details…'
                      : hasLoadError
                      ? loadErrorMessage ??
                            'Release details are temporarily unavailable.'
                      : 'No release details are available right now.'
                : latestStableRelease != null
                ? 'The latest ${currentRelease.displayName} release is ready.'
                : isLegacyFallback
                ? 'A verified public download will appear once the release channel reconnects.'
                : currentRelease.availabilityMessage;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download Cashly Lao',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  supportingText,
                  style: const TextStyle(
                    color: Color(0xFFDFF2E1),
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                if (currentRelease != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReleaseDetail(label: currentRelease.statusLabel),
                      if (currentRelease.version case final version?)
                        _ReleaseDetail(label: 'Version $version'),
                      if (currentRelease.buildNumber case final buildNumber?)
                        _ReleaseDetail(label: 'Build $buildNumber'),
                      if (currentRelease.releaseDateLabel case final date?)
                        _ReleaseDetail(label: 'Released $date'),
                      if (currentRelease.fileSizeLabel case final fileSize?)
                        _ReleaseDetail(label: '$fileSize download'),
                      if (currentRelease.minimumOsVersion case final minimumOs?)
                        _ReleaseDetail(label: minimumOs),
                      if (currentRelease.packageFormat
                          case final packageFormat?)
                        _ReleaseDetail(label: packageFormat),
                    ],
                  ),
                  if (currentRelease.releaseNotes case final releaseNotes?) ...[
                    const SizedBox(height: 14),
                    Text(
                      releaseNotes,
                      style: const TextStyle(
                        color: Color(0xFFDFF2E1),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (releaseNotesUrl != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => launchUrl(
                        releaseNotesUrl,
                        mode: LaunchMode.platformDefault,
                        webOnlyWindowName: '_self',
                      ),
                      child: const Text(
                        'View full release notes on GitHub →',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  if (currentRelease.artifactName case final artifactName?) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Package: $artifactName',
                      style: const TextStyle(
                        color: Color(0xFFDFF2E1),
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (currentRelease.sha256 case final sha256?) ...[
                    const SizedBox(height: 5),
                    SelectableText(
                      'SHA-256: $sha256',
                      style: const TextStyle(
                        color: Color(0xFFDFF2E1),
                        fontSize: 10,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ],
            );
            final action = Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 210,
                    height: 54,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (latestStableRelease case final availableRelease?)
                  FilledButton.icon(
                    onPressed: () => onOpenRelease(availableRelease),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _LandingColors.greenDark,
                      minimumSize: const Size(210, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(availableRelease.actionLabel),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(210, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      side: const BorderSide(color: Color(0xFFDFF2E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      hasLoadError ? 'Try again' : 'Check availability',
                    ),
                  ),
                if (isFallback) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(210, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Refresh release details'),
                  ),
                ],
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Safe download. No registration required.',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Color(0xFFDFF2E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentRelease?.installationNote case final note?) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFDFF2E1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (currentRelease?.packageFormat
                        case final format?) ...[
                      const SizedBox(height: 4),
                      Text(
                        format,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFDFF2E1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [details, const SizedBox(height: 30), action],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 32),
                      action,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _ReleaseDetail extends StatelessWidget {
  const _ReleaseDetail({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VersionHistorySection extends StatelessWidget {
  const _VersionHistorySection({required this.history});

  final List<ReleaseHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return _LandingSection(
      eyebrow: 'Release history',
      title: 'Previous versions, still verified.',
      description:
          'Every past Android release listed here passed the same signature and checksum verification as the current download.',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _LandingColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < history.length; index++) ...[
              _VersionHistoryRow(entry: history[index]),
              if (index < history.length - 1)
                const Divider(height: 1, color: _LandingColors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionHistoryRow extends StatelessWidget {
  const _VersionHistoryRow({required this.entry});

  final ReleaseHistoryEntry entry;

  Future<void> _open(BuildContext context) async {
    final downloadUri = entry.platformRelease.downloadUrl;
    if (downloadUri == null) return;
    final opened = await launchUrl(
      downloadUri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start the download.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = entry.platformRelease;
    final detailParts = [
      if (release.releaseDateLabel case final date?) 'Released $date',
      ?release.fileSizeLabel,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cashly Lao v${entry.version}',
                  style: const TextStyle(
                    color: _LandingColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detailParts.join(' · '),
                    style: const TextStyle(
                      color: _LandingColors.mutedInk,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => _open(context),
            style: TextButton.styleFrom(
              foregroundColor: _LandingColors.greenDark,
            ),
            icon: const Icon(Icons.download_rounded, size: 17),
            label: const Text('Download APK'),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        question: 'Is Cashly Lao free?',
        answer:
            'Yes. Cashly Lao is free to download and use for personal expense tracking and financial planning.',
      ),
      (
        question: 'Does Cashly Lao work offline?',
        answer:
            'Cashly is designed to stay useful when a connection drops. An internet connection is still needed for sign-in and to sync changes securely across your devices.',
      ),
      (
        question: 'Is my financial data secure?',
        answer:
            'Your data is protected with Firebase Authentication, Firestore security rules, and encrypted HTTPS connections. Your financial records are tied only to your account.',
      ),
      (
        question: 'Which platforms are supported?',
        answer:
            'The release cards above show the current status for Android, iOS, Windows, and Mac. Available platforms include the latest official download; upcoming platforms are clearly marked Coming soon.',
      ),
      (
        question: 'How does cloud synchronization work?',
        answer:
            'When you are signed in, Cashly securely synchronizes your financial records with your account so your information can stay consistent across supported devices.',
      ),
      (
        question: 'How is the Smart Money Score calculated?',
        answer:
            'Cashly calculates the score from your actual balances, cash flow, budgets, and recent spending patterns. It explains the key factors so you can understand what changed.',
      ),
      (
        question: 'Where can I download the latest release?',
        answer:
            'Use the download area on this page. It reads from Cashly Lao’s official release channel and shows the current version, release details, and download action automatically.',
      ),
    ];

    return _LandingSection(
      eyebrow: 'Questions, answered',
      title: 'Simple answers before you get started.',
      description:
          'Cashly is designed to be straightforward - including how it works and how it protects your information.',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _LandingColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 6,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                iconColor: _LandingColors.green,
                collapsedIconColor: _LandingColors.mutedInk,
                title: Text(
                  items[index].question,
                  style: const TextStyle(
                    color: _LandingColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      items[index].answer,
                      style: const TextStyle(
                        color: _LandingColors.mutedInk,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (index < items.length - 1)
                const Divider(height: 1, color: _LandingColors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandingSection extends StatelessWidget {
  const _LandingSection({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: _LandingColors.green,
              fontSize: 12,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              title,
              style: const TextStyle(
                color: _LandingColors.ink,
                fontSize: 38,
                height: 1.08,
                letterSpacing: -1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 15),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              description,
              style: const TextStyle(
                color: _LandingColors.mutedInk,
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 38),
          child,
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter({
    required this.onPrivacy,
    required this.onTerms,
    required this.onContact,
    required this.onFeatures,
  });

  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onContact;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 112),
      padding: const EdgeInsets.symmetric(vertical: 44),
      color: const Color(0xFFF1F6F1),
      child: _LandingShell(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 700;
            final brand = const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CashlyLogoMark(size: 30),
                SizedBox(width: 10),
                Text(
                  'Cashly Lao',
                  style: TextStyle(
                    color: _LandingColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );
            final links = Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _FooterLink(label: 'Privacy Policy', onPressed: onPrivacy),
                _FooterLink(label: 'Terms of Service', onPressed: onTerms),
                _FooterLink(label: 'Contact', onPressed: onContact),
                _FooterLink(label: 'Features', onPressed: onFeatures),
                const _FooterLink(label: 'Facebook - coming soon'),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stacked) ...[
                  brand,
                  const SizedBox(height: 20),
                  links,
                ] else
                  Row(
                    children: [
                      brand,
                      const Spacer(),
                      Flexible(child: links),
                    ],
                  ),
                const SizedBox(height: 28),
                const Text(
                  'Copyright © 2026 Cashly Lao. Built with care in Laos.',
                  style: TextStyle(
                    color: _LandingColors.mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: onPressed == null
            ? _LandingColors.mutedInk.withValues(alpha: .65)
            : _LandingColors.mutedInk,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _FadeInUp extends StatefulWidget {
  const _FadeInUp({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

ButtonStyle _primaryButtonStyle({bool compact = false}) {
  return FilledButton.styleFrom(
    backgroundColor: _LandingColors.green,
    foregroundColor: Colors.white,
    minimumSize: Size(0, compact ? 42 : 54),
    padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 21),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
  );
}
