import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/models/notification_log_model.dart';
import '../../homeMain/controllers/homeMain_controllers.dart';
import '../../homeMain/views/homeMain_view.dart';
import '../../../routes/app_pages.dart';
import '../../../data/providers/theme_provider.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationHistoryView extends StatelessWidget {
  const NotificationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationProvider provider = Get.find();
    final HomeMainController mainController = Get.find();
    final theme = Theme.of(context);
    final themeProvider = Get.find<ThemeProvider>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Notifikasi',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await provider.clearLogs();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<NotificationLogModel>>(
        valueListenable: provider.listenable(),
        builder: (context, box, _) {
          final logs = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (logs.isEmpty) {
            return const Center(child: Text('Tidak ada notifikasi'));
          }

          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: log.type == 'push' ? Colors.red[100] : Colors.blue[100],
                  child: Icon(
                    log.type == 'push' ? Icons.notifications_active : Icons.alarm,
                    color: log.type == 'push' ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text(log.title),
                subtitle: Text(log.body),
                trailing: Text(
                  DateFormat('dd/MM HH:mm').format(log.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: mainController.selectedIndex.value,
          onTap: (index) {
            if (index == 0) Get.offAllNamed(Routes.HOME_MAIN);
            
            if (index == 1) {
            Get.toNamed(Routes.TODO_LIST);
            }

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
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),

    );
  }
}

