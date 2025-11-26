import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/values/app_colors.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header + Welcome Card horizontal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: themeProvider.isDarkMode
                          ? AppColors.darkIcon
                          : theme.colorScheme.primary,
                    ),
                    tooltip: 'Reload API Data',
                    onPressed: controller.fetchDataFromApi,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.userEmail ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {},
                        child: Obx(
                          () => Text(
                            'Lokasi kamu',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.isDarkMode
                                  ? AppColors.darkIcon
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Obx(
                        () => IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: themeProvider.isDarkMode
                                ? AppColors.darkIcon
                                : theme.colorScheme.primary,
                          ),
                          tooltip: themeProvider.isDarkMode
                              ? 'Light Mode'
                              : 'Dark Mode',
                          onPressed: themeProvider.toggleTheme,
                        ),
                      ),
                      Obx(
                        () => IconButton(
                          icon: Icon(
                            Icons.location_on,
                            color: themeProvider.isDarkMode
                                ? AppColors.darkIcon
                                : theme.colorScheme.primary,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Field
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkIcon
                      : AppColors.primary,
                ),
                hintText: 'Cari layanan...',
                hintStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkIcon
                      : AppColors.primary,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        ),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bagian scrollable: promo + list API
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchProductsWithProgress,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = width < 400
                            ? 150.0
                            : width < 600
                                ? 200.0
                                : width < 800
                                    ? 300.0
                                    : 400.0;
                        return Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/diskon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
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
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: controller.filteredProduk.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = controller.filteredProduk[index];

                          return Card(
                            child: InkWell(
                              onTap: controller.goToHome,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          controller.assetImages[
                                              index % controller.assetImages.length],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['nama'] ?? 'Tanpa Nama',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigator dengan Profile popup
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: themeProvider.isDarkMode
              ? AppColors.darkIcon
              : theme.colorScheme.primary,
          unselectedItemColor: themeProvider.isDarkMode
              ? AppColors.darkTextSecondary
              : Colors.grey,
          currentIndex: controller.selectedIndex.value,
          onTap: (index) {
            if (index == 3) {
              // Profile popup
              final RenderBox bar = context.findRenderObject() as RenderBox;
              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final position = RelativeRect.fromRect(
                Rect.fromPoints(
                  bar.localToGlobal(Offset.zero, ancestor: overlay),
                  bar.localToGlobal(bar.size.bottomRight(Offset.zero), ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );

              showMenu<String>(
                context: context,
                position: position,
                items: [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.loggedIn,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
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
              ).then((value) {
                if (value == 'logout') {
                  Get.find<AuthController>().logout();
                }
              });
            } else {
              controller.selectedIndex.value = index;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'Promotions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
