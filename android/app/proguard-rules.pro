# Firebase (Auth/Firestore/Crashlytics/Analytics/Messaging), Google Sign-In,
# and flutter_local_notifications all ship their own consumer ProGuard rules
# bundled in their AARs, which R8 applies automatically — nothing here
# duplicates those. These are the app-specific keep rules layered on top,
# for the parts most likely to break under R8's default obfuscation.

# Crashlytics needs de-obfuscated stack traces to be meaningful; keep line
# numbers and source file names rather than stripping them.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Core's SplitCompat/deferred-component classes are referenced
# reflectively by the Flutter engine's own embedding even when this app
# never uses dynamic feature delivery — missing-class warnings for these
# are expected and safe to ignore rather than fail the build over.
-dontwarn com.google.android.play.core.**
