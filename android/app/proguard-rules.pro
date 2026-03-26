# Preserve telecom framework
-keep class android.telecom.** { *; }
-keep interface android.telecom.** { *; }
-keepnames class * implements android.telecom.ConnectionService
-keepnames class * implements android.telecom.InCallService
-keepnames class * implements android.telecom.CallScreeningService

# Preserve app classes
-keep class com.mangrule.dailathon.telecom.** { *; }
-keep class com.mangrule.dailathon.bridge.** { *; }
-keep class com.mangrule.dailathon.audio.** { *; }
-keep class com.mangrule.dailathon.notification.** { *; }
-keep class com.mangrule.dailathon.contacts.** { *; }
-keep class com.mangrule.dailathon.blocking.** { *; }
-keep class com.mangrule.dailathon.forwarding.** { *; }
-keep class com.mangrule.dailathon.multisim.** { *; }
-keep class com.mangrule.dailathon.vibration.** { *; }
-keep class com.mangrule.dailathon.oem.** { *; }

# Preserve Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class io.flutter.embedding.engine.FlutterEngine {
    *** dartExecutor;
}

# Preserve Hilt
-keep class com.google.dagger.** { *; }
-keep interface com.google.dagger.** { *; }
-keep class javax.inject.** { *; }

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

-dontnote android.net.http.**
-dontnote org.apache.commons.codec.**
-dontnote org.apache.http.**
