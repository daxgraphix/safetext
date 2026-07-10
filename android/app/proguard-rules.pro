# Keep the cryptography plugin's native bindings and Hive's reflection-free
# binary adapters intact under R8/ProGuard minification.

-keep class com.namida.cryptography.** { *; }
-keep class * extends com.google.hive.** { *; }
-dontwarn javax.annotation.**
-keepattributes *Annotation*

# Flutter / Play Core (deferred components not used, but keep quiet)
-dontwarn io.flutter.embedding.**
