import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/values/app_colors.dart';
import '../../../routes/app_pages.dart';

import '../controllers/todo_controller.dart';
import '../../../data/providers/theme_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../homeMain/controllers/homeMain_controllers.dart';

class TodoListView extends GetView<TodoController> {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Get.find<ThemeProvider>();
    final authController = Get.find<AuthController>();

    final bool isDark = themeProvider.isDarkMode;

    final Color darkSurface = theme.colorScheme.surface;
    final Color darkCard = theme.colorScheme.surfaceVariant;

    return Scaffold(
      // =====================================================
      // APPBAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),

            // ===== CUSTOM BACK BUTTON =====
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: isDark ? AppColors.darkIcon : Colors.black,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ===== TITLE (BESAR) =====
            Text(
              "Services",
              style: TextStyle(
                color: isDark ? AppColors.darkIcon : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,       // ← DIBESARKAN
              ),
            ),
          ],
        ),
      ),

      extendBodyBehindAppBar: true,

      // =====================================================
      // BODY
      // =====================================================
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80),

            // ================= BANNER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    "assets/diskon.png",
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ================= BUTTON TAMBAH =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => controller.goToForm(),
                borderRadius: BorderRadius.circular(10),
                splashColor: isDark ? AppColors.darkTextSecondary : Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? darkSurface : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),

                    // 🔥 BORDER DARK THEME SUDAH DIGANTI
                    border: Border.all(
                      color: isDark ? AppColors.darkIcon : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Tambah",
                    style: TextStyle(
                      color: isDark ? AppColors.darkIcon : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= LIST AREA =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? darkSurface : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),

                  child: controller.todos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.checklist_rounded,
                                size: 96,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada layanan",
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: controller.todos.length,
                          itemBuilder: (context, index) {
                            final todo = controller.todos[index];
                            final done = todo.isCompleted;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? darkCard : const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),

                                // 🔥 BORDER TODOLIST DARK THEME DIGANTI KE darkIcon
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkIcon
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => controller.toggleTodo(todo),
                                    icon: Icon(
                                      done ? Icons.check_circle : Icons.check_circle_outline,
                                      color: done ? Colors.green : Colors.grey,
                                      size: 30,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          todo.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: done ? TextDecoration.lineThrough : null,
                                            color: isDark ? AppColors.darkIcon : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          todo.description.isEmpty ? "Detail" : todo.description,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () => controller.goToForm(todo: todo),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: isDark ? AppColors.darkIcon : theme.colorScheme.primary,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () => controller.deleteTodo(todo),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        );
      }),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: isDark ? AppColors.darkIcon : theme.colorScheme.primary,
        unselectedItemColor: isDark ? AppColors.darkTextSecondary : Colors.grey,

        onTap: (index) {
          if (index == 0) Get.offAllNamed(Routes.HOME_MAIN);
          if (index == 3) {
            final homeMainController = Get.find<HomeMainController>();

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                MediaQuery.of(context).size.width - 160,
                MediaQuery.of(context).size.height -
                    kBottomNavigationBarHeight -
                    120,
                0,
                0,
              ),
              items: [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Logged in", style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        homeMainController.userEmail ?? "-",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      const Text("Logout"),
                    ],
                  ),
                ),
              ],
            ).then((value) {
              if (value == "logout") authController.logout();
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
