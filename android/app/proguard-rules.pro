# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /path/to/android/sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools-proguard.html

# Add any custom rules here that might be needed for your app.
# Seal Classes support usually doesn't need rules, but some plugins do.
-keep class com.google.firebase.** { *; }
-keep class com.supportclub.carte.** { *; }
