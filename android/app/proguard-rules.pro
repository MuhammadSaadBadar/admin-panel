# ----------------------------------------------------------------------------
# ProGuard / R8 keep rules for Mama Health Admin (release builds)
#
# The backend uses JWT auth via Dio; Dio and GetX ship their own consumer
# rules. These rules keep the classes the app references reflectively or via
# the JSON serialization mapping (fromJson cast from Map) so they are not
# stripped/renamed at shrink time.
# ----------------------------------------------------------------------------

# Keep the MainActivity (entry point) and Flutter embedding.
-keep class com.mamahealth.admin.MainActivity { *; }
-keep class io.flutter.plugins.** { *; }

# Keep model classes used for JSON parsing (fromJson). If you add more models,
# add their package/class here. Using a broad keep on the feature models dir
# avoids brittle class-name lists.
-keep class com.mamahealth.** { *; }

# Dio / HTTP keep rules (defensive; Dio ships consumer rules but keep for safety).
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# GetX uses reflection in some hot-reload/dev paths; keep its internals.
-keep class com.getbase.** { *; }
-keep class com.getx.** { *; }

# Keep Gson/Jackson if either is added later for serialization.
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }

# Flutter engine already ships with its own rules; do not strip it further.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# General: keep line numbers for readable stack traces in crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
