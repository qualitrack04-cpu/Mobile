# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio & OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Gson (kalau pakai)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Model classes kamu (ganti dengan package name asli)
-keep class com.yourapp.models.** { *; }
