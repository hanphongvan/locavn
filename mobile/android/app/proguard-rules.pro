# Flutter embedding (JNI / reflection)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Store / deferred components (harmless if unused)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Maps / Play services (maps + common reflection)
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# OkHttp / Okio (often pulled transitively; Dio is Dart-side but plugins may use OkHttp)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Line numbers / attributes for readable stack traces
-keepattributes *Annotation*, Signature, Exception, InnerClasses, EnclosingMethod, SourceFile, LineNumberTable
