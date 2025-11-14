import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core
import 'package:my_app/app/core/theme/app_theme.dart';
import 'package:my_app/app/core/values/app_strings.dart';

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


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  
  // 🔹 Style status bar & navigation bar default
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // 🔹 Inisialisasi semua service async
    await Get.putAsync(() => SupabaseService().init());
    await Get.putAsync(() => ApiService().init());
    Get.put(AuthProvider());
    Get.put(NoteProvider());
    Get.put(StorageService());
    await Get.putAsync(() => LocalStorageService().init());
    Get.put(TodoProvider());

    // 🔹 Theme Provider (HANYA SEKALI)
    final themeProvider = Get.put(ThemeProvider());
    await themeProvider.init();

    if (kDebugMode) {
      debugPrint('✅ All services initialized successfully');
    }

    // 🔹 Jalankan aplikasi
    runApp(const MyApp());

  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Error during initialization:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }

    // 🔹 Tampilan error fallback (jika init gagal)
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
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

      return GetMaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
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
      );
    });
  }
}
