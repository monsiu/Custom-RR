# Flutter wrapper.
# NOTE: deliberately no catch-all "-keep class io.flutter.** { *; }". That rule
# would retain io.flutter.embedding.engine.deferredcomponents.
# PlayStoreDeferredComponentManager, which hard-references the proprietary
# Google Play Core classes and drags them into the APK (rejected by F-Droid's
# scanner). This app uses the default Application, so the deferred-components
# manager is unreachable and R8 can tree-shake it, along with Play Core.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
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
