# Google ML Kit ProGuard Kuralları
-keep class com.google.mlkit.** {*;}
-dontwarn com.google.mlkit.**

-keep class com.google.android.gms.internal.mlkit_vision_text_common.** {*;}
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**