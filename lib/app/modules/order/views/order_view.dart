import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/providers/theme_provider.dart';
import '../../note/views/note_list_view.dart';
import '../../note/bindings/note_binding.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final String service = (Get.arguments is String && Get.arguments != null)
        ? Get.arguments as String
        : 'WASH';

    final themeProvider = Get.find<ThemeProvider>();

    return Obx(() => Scaffold(
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'ORDER',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? AppColors.darkCardBorder
                    : Colors.white,
              ),
            ),
            centerTitle: false,
            leading: _iconCard(
              icon: Icons.arrow_back,
              onTap: () => Get.back(),
              isDarkMode: themeProvider.isDarkMode,
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Card besar (Wash)
                Container(
                  width: size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[900]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? AppColors.darkCardBorder
                          : AppColors.primary.withOpacity(1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.7)
                            : Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 110,
                        child: Image.asset(
                          'assets/mesin_cuci.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode
                                  ? AppColors.darkCardBorder
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wash Only',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.isDarkMode
                                  ? AppColors.darkCardBorder.withOpacity(0.8)
                                  : Colors.grey[700],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Grid mesin
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _mesinItem('Mesin A', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin B', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin C', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin D', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin E', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin F', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin G', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                      _mesinItem('Mesin H', 'assets/mesin_cuci.png', themeProvider.isDarkMode),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ));
  }

  /// Card mesin yang bisa di-tap
  Widget _mesinItem(String title, String img, bool isDarkMode) {
    return InkWell(
      onTap: () {
        // Navigasi ke NoteListView via direct page push + binding to ensure controller is created
        Get.to(() => const NoteListView(), binding: NoteBinding(), arguments: title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? AppColors.darkCardBorder : AppColors.primary,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(img, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    isDarkMode ? AppColors.darkCardBorder : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back button
  static Widget _iconCard({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkCardBorder : AppColors.primary,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.7)
                : Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              color: isDarkMode ? AppColors.darkCardBorder : Colors.black),
        ),
      ),
    );
  }
}
