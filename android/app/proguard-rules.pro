# Règles ProGuard/R8 pour le build release de SIC Mobile.
# La plupart des plugins Flutter embarquent leurs propres règles « consumer »
# (appliquées automatiquement par R8). On ajoute ici les garde-fous pour le code
# sensible (auth native, sérialisation par réflexion) et pour réduire le bruit.

# --- Flutter ---------------------------------------------------------------
-ignorewarnings
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn androidx.**

# --- Authentification (biométrie / local_auth) -----------------------------
# AndroidX biometric + plugins d'auth utilisent de la réflexion / JNI.
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# --- Hive (adapters générés par réflexion) ---------------------------------
-keep class **.*TypeAdapter { *; }
-keep @hive.annotations.** class * { *; }

# --- Sentry ----------------------------------------------------------------
# Conserver les traces lisibles ; Sentry fournit ses propres règles consumer.
-keepattributes SourceFile,LineNumberTable
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# --- Divers ----------------------------------------------------------------
# Conserver les annotations et signatures génériques (réflexion JSON éventuelle).
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
