import 'url_strategy_stub.dart'
    if (dart.library.html) 'url_strategy_web.dart'
    as platform;

/// Configures browser-only routing without importing web libraries on native
/// targets. The web implementation uses path URLs; native apps do nothing.
void configureWebUrlStrategy() => platform.configureWebUrlStrategy();
