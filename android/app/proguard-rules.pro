# =======================
# Flutter Wrapper (Core)
# =======================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# =======================
# Flutter WebRTC
# =======================
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }

# =======================
# Firebase Messaging
# =======================
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# =======================
# ConnectyCube Call Kit
# =======================
-keep class com.connectycube.pushnotifications.** { *; }
-keep class com.connectycube.call.** { *; }
-keep class com.connectycube.flutter.callkit.** { *; }
-dontwarn com.connectycube.**

# =======================
# Your App's Package
# =======================
-keep class com.yourcompany.yourapp.** { *; }


# =======================
# (Optional) Suppress warnings for missing classes
# Uncomment if you see warnings for classes you know are not used
# -dontwarn io.flutter.util.**
# -dontwarn io.flutter.app.**
# -dontwarn com.connectycube.messenger.**
