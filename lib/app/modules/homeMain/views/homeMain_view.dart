import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_strings.dart';
import '../../../data/providers/theme_provider.dart';
import '../../auth/controllers/auth_controllers.dart';
import '../controllers/homeMain_controllers.dart'; // pastikan controllernya ada

class HomeMainView extends GetView<HomeMainController> {
  const HomeMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Get.find<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reload API Data',
          onPressed: controller.fetchDataFromApi, // panggil pitching API
        ),
        title: const Text(AppStrings.homeMain),
        actions: [
          // Theme Toggle Button
          Obx(() => IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip:
                    themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: themeProvider.toggleTheme,
              )),

          // Profile Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_rounded),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.loggedIn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.userEmail ?? '-',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    const Text(AppStrings.logout),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Get.find<AuthController>().logout();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const CircularProgressIndicator();
          } else if (controller.apiData.isEmpty) {
            return const Text('No data found. Pull to refresh.');
          } else {
            return ListView.builder(
              itemCount: controller.apiData.length,
              itemBuilder: (context, index) {
                final item = controller.apiData[index];
                return ListTile(
                  title: Text(item['title'] ?? 'No title'),
                  subtitle: Text(item['description'] ?? ''),
                );
              },
            );
          }
        }),
      ),
    );
  }
}
