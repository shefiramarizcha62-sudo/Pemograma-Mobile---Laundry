import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_strings.dart';
import '../controllers/note_controller.dart';
import 'note_form_view.dart';

class NoteListView extends GetView<NoteController> {
  const NoteListView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.notes.isEmpty && !controller.isLoading.value) {
        controller.loadNotes();
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Get.back(),
        ),
        title: const Text(AppStrings.notes),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Get.snackbar('Cart', 'Cart tapped'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Get.snackbar('Notifications', 'Notifications tapped'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 96,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.noNotesYet,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tapToAddNote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notes.length + 2,
            itemBuilder: (context, index) {

              // ====== BAGIAN FOTO PALING ATAS (index == 0) ======
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160, // tinggi bisa kamu ubah sesuka
                      width: double.infinity,
                      child: Image.asset(
                        'assets/diskon.png',
                        fit: BoxFit.cover, // FULL COVER
                      ),
                    ),
                  ),
                );
              }


              // ====== TOMBOL TAMBAH ======
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (Get.isRegistered<NoteFormController>()) Get.delete<NoteFormController>();
                        } catch (_) {}

                        final result = await Get.bottomSheet(
                          FractionallySizedBox(
                            heightFactor: 0.8,
                            child: NoteFormView(),
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );

                        if (result != null) {
                          await controller.loadNotes();
                          if (result is String && result.isNotEmpty) {
                            Get.snackbar('Success', result,
                                backgroundColor: Colors.green, colorText: Colors.white);
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                );
              }

              // ====== ITEM NOTE ======
              final note = controller.notes[index - 2];
              final imageUrl = note.imageUrl;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined,
                                  color: theme.colorScheme.onSurfaceVariant),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isNotEmpty ? note.title : 'Nama Customer',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.content.isNotEmpty ? note.content : 'Berat',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final done = controller.isDone(note, index: index - 2);
                          return IconButton(
                            onPressed: () => controller.toggleDone(note, index: index - 2),
                            icon: Icon(
                              done ? Icons.check_circle : Icons.check_circle_outline,
                              color: done ? Colors.green[600] : theme.colorScheme.primary,
                            ),
                          );
                        }),
                        IconButton(
                          onPressed: () async {
                            try {
                              if (Get.isRegistered<NoteFormController>()) Get.delete<NoteFormController>();
                            } catch (_) {}

                            final result = await Get.bottomSheet(
                              FractionallySizedBox(
                                heightFactor: 0.8,
                                child: NoteFormView(initialNote: note),
                              ),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );

                            if (result != null) {
                              await controller.loadNotes();
                              if (result is String && result.isNotEmpty) {
                                Get.snackbar('Success', result,
                                    backgroundColor: Colors.green, colorText: Colors.white);
                              }
                            }
                          },
                          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                        ),
                        IconButton(
                          onPressed: () => controller.deleteNote(note),
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      }),

      floatingActionButton: null,
    );
  }
}
