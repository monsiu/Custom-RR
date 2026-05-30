# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core is excluded from the F-Droid build (deferred components are
# unused); silence the references left in the Flutter embedding.
-dontwarn com.google.android.play.core.**

# Google Material Components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# AndroidX
-dontwarn androidx.**

# OkHttp / Okio (transitive via plugins)
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep generic signatures for reflection (cached_network_image, etc.)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
