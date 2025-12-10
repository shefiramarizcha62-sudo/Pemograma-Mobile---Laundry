import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core
import 'package:my_app/app/core/theme/app_theme.dart';
import 'package:my_app/app/core/values/app_strings.dart';
import 'package:my_app/app/core/values/app_colors.dart';

// Services
import 'package:my_app/app/data/services/api_service.dart';
import 'package:my_app/app/data/services/local_storage_service.dart';
import 'package:my_app/app/data/services/supabase_service.dart';
import 'package:my_app/app/data/services/storage_service.dart';

// Providers
import 'package:my_app/app/data/providers/auth_provider.dart';
import 'package:my_app/app/data/providers/note_provider.dart';
import 'package:my_app/app/data/providers/todo_provider.dart';
import 'package:my_app/app/data/providers/theme_provider.dart';

// Routes
import 'package:my_app/app/routes/app_pages.dart';

import 'package:my_app/app/modules/auth/controllers/auth_controller.dart';

// ADD: Notification
import 'package:my_app/app/data/providers/notification_provider.dart';
import 'package:my_app/app/data/services/notification_handler.dart';
import 'package:my_app/app/data/models/notification_log_model.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("📩 Background Message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Status bar style default
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // ============================================
    // 1️⃣ INIT ALL SERVICES DULU
    // ============================================
    await Get.putAsync(() => SupabaseService().init());
    Get.put(ApiService());
    Get.put(AuthProvider());
    Get.put(AuthController());
    Get.put(NoteProvider());
    Get.put(StorageService());

    // LocalStorageService WAJIB sebelum Notification
    await Get.putAsync(() => LocalStorageService().init());

    Get.put(TodoProvider());
    Get.put(NotificationProvider());

    final themeProvider = Get.put(ThemeProvider());
    await themeProvider.init();

    // ============================================
    // 2️⃣ BARU INIT NOTIFICATION SETELAH SEMUA READY
    // ============================================
    final notificationHandler = NotificationHandler();
    await notificationHandler.initLocalNotification();
    await notificationHandler.initPushNotification();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      NotificationHandler().showNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );
    });

    String? token = await FirebaseMessaging.instance.getToken();
    print("🔥🔥🔥 FCM TOKEN: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("♻️ NEW TOKEN: $newToken");
    });

    if (kDebugMode) {
      debugPrint('✅ All services & notification initialized successfully');
    }

  } catch (e, stackTrace) {
    debugPrint("❌ Init error: $e");
    debugPrint(stackTrace.toString());
  }

  // Running app once
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Get.find<AuthProvider>();
    final themeProvider = Get.find<ThemeProvider>();

    return Obx(() {
      // 🔹 Sinkronisasi warna sistem dengan tema
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              themeProvider.isDarkMode ? const Color(0xFF000000) : Colors.white,
          systemNavigationBarIconBrightness:
              themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
        ),
      );

       return Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: GetMaterialApp(
          title: AppStrings.appName,
          theme: AppTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: Colors.transparent, // wajib supaya gradient terlihat
          ),
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: authProvider.isAuthenticated
              ? Routes.HOME_MAIN
              : Routes.LOGIN,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }
}