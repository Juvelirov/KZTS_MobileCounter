# Защита WorkDatabase_Impl от удаления (используется WorkManager через рефлексию)
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Защита конструкторов Worker'ов
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}

# Базовые правила для Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Защита WorkManager и Room (для release-сборки)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker { <init>(...); }