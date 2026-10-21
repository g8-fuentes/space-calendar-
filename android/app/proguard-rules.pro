# Mantém as classes dos plugins chamadas por JNI ou por reflexão,
# que o R8 removeria no APK de release.
-keep class io.flutter.plugins.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
