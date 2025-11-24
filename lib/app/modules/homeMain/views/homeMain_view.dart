import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_strings.dart';
import '../../../data/providers/theme_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/homeMain_controllers.dart';


class HomeMainView extends GetView<HomeMainController> {
  const HomeMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Get.find<ThemeProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.isWelcomeShown(true);
    });

    
    return Scaffold(
      appBar: AppBar(
        // Leading: reload / refresh API
        leading: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reload API Data',
          onPressed: controller.fetchDataFromApi,
        ),

        // Title (tengah)
        centerTitle: true,
        title: const Text('Gangnam Laundry'),

        // Actions: theme toggle + profile
        actions: [
          // Theme Toggle
          Obx(() => IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip:
                    themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: themeProvider.toggleTheme,
              )),

          // Profile popup
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
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.userEmail ?? '-',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
      
      // Body: search + list hasil API
      body: RefreshIndicator(
        onRefresh: controller.fetchProductsWithProgress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 👇 Tambahkan ini di dalam Column sebelum TextField
              Obx(() => controller.isWelcomeShown.value
                ? _WelcomeCard(userEmail: controller.userEmail ?? '-', theme: theme)
                  : const SizedBox.shrink()),
                    const SizedBox(height: 12),

              // Optional: search field
              TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Cari layanan...',
                  suffixIcon: Obx(() => controller.searchQuery.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        )),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Konten: loading / empty / list
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.filteredProduk.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada layanan. Tarik untuk memuat ulang.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.filteredProduk.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = controller.filteredProduk[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            // Saat menekan item, langsung ke halaman Home (notes & todos)
                            controller.goToHome();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_laundry_service,
                                    color: theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _WelcomeCard extends StatelessWidget {
  final String userEmail;
  final ThemeData theme;

  const _WelcomeCard({
    required this.userEmail,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.waving_hand, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.welcomeBack,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
