# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# kotlinx.serialization keep rules are intentionally NOT declared here.
# kotlinx-serialization-core ships them inside the jar
# (META-INF/com.android.tools/r8/*.pro, including the R8 full-mode rules) and R8
# applies them automatically.

# yubikit keep rules are intentionally NOT declared here. The
# com.yubico.yubikit:android AAR ships them as consumer rules, including
# `-keepnames class com.yubico.yubikit.**`, which already preserves exception
# class names so they are not obfuscated in log output.

-dontwarn edu.umd.cs.findbugs.annotations.SuppressFBWarnings

# app specific rules
-keep public class com.yubico.authenticator.logging.BufferAppender
-keepclassmembers class com.yubico.authenticator.logging.BufferAppender { *; }

# consumer rules for logback-android
# The logback-android AAR ships no proguard.txt, so we carry its rules here.
# see: https://github.com/tony19/logback-android/blob/v_3.0.0/logback-android/consumer-rules.pro
-keepclassmembers class ch.qos.logback.classic.pattern.* { <init>(); }

-keepclassmembers class ch.qos.logback.** { *; }
-keepclassmembers class org.slf4j.impl.** { *; }
-keepattributes *Annotation*

-keep public class ch.qos.logback.classic.android.LogcatAppender


-keep class org.bouncycastle.** { *; }

# these are not part of Android SDK (referenced by logback via JNDI)
-dontwarn javax.naming.Binding
-dontwarn javax.naming.NamingEnumeration
-dontwarn javax.naming.NamingException
-dontwarn javax.naming.directory.Attribute
-dontwarn javax.naming.directory.Attributes
-dontwarn javax.naming.directory.DirContext
-dontwarn javax.naming.directory.InitialDirContext
-dontwarn javax.naming.directory.SearchControls
-dontwarn javax.naming.directory.SearchResult
