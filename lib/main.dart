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

// Notification
import 'package:my_app/app/data/providers/notification_provider.dart';
import 'package:my_app/app/data/services/notification_handler.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:developer';

/// ================================
/// 🔔 Background handler (WAJIB TOP LEVEL)
/// ================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("📩 Background Message: ${message.messageId}");
}

/// ================================
/// 🔔 Handle routing when notif tapped
/// ================================
void _handleNotificationNavigation(RemoteMessage message) {
  // Delay kecil supaya GetX & routing siap
  Future.delayed(const Duration(milliseconds: 300), () {
    Get.toNamed(Routes.NOTIFICATION);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ================================
  // Init Firebase
  // ================================
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ================================
  // Status bar style default
  // ================================
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
    // 1️⃣ INIT ALL SERVICES
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

    // 🔔 NotificationHandler sebagai singleton
    final notificationHandler = Get.put(NotificationHandler());

    final themeProvider = Get.put(ThemeProvider());
    await themeProvider.init();

    // ============================================
    // 2️⃣ INIT NOTIFICATION (LOCAL + FCM)
    // ============================================
    await notificationHandler.initLocalNotification();
    await notificationHandler.initPushNotification();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Permission (Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      notificationHandler.showNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );
    });

    // ================================
    // 🔔 ROUTING DARI NOTIF
    // ================================

    // App dibuka dari TERMINATED (mati total)
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }

    // App dibuka dari BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _handleNotificationNavigation(message);
      },
    );

    // ================================
    // Debug token
    // ================================
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint("🔥🔥🔥 FCM TOKEN: $token");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint("♻️ NEW TOKEN: $newToken");
      }
    });

    if (kDebugMode) {
      debugPrint('✅ All services & notification initialized successfully');
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Init error: $e");
    debugPrint(stackTrace.toString());
  }

  // ================================
  // Run App
  // ================================
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Get.find<AuthProvider>();
    final themeProvider = Get.find<ThemeProvider>();

    return Obx(() {
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
            scaffoldBackgroundColor: Colors.transparent,
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
