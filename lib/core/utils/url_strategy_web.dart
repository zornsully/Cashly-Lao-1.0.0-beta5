import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Removes hash fragments from browser routes such as `/features`.
void configureWebUrlStrategy() => usePathUrlStrategy();
