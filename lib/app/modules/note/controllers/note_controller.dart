import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/values/app_strings.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/note_provider.dart';
import '../../../data/services/storage_service.dart';
import 'package:my_app/app/routes/app_pages.dart';
import '../views/note_form_view.dart';

class NoteController extends GetxController {
  static const bucketId = 'note-images';

  final NoteProvider _noteProvider = Get.find();
  final StorageService _storageService = Get.find();

  final notes = <NoteModel>[].obs;
  final isLoading = true.obs;
  // keep UI-only done/toggle state for notes (key: note id or index fallback)
  final RxMap<String, bool> doneStatus = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _ensureBucket();
    loadNotes();
  }


  Future<void> _ensureBucket() async {
    try {
      final bucket = await _storageService.getBucket(bucketId);
      if (!bucket.public) {
        await _storageService.updateBucket(
          bucketId,
          options: const BucketOptions(public: true),
        );
      }
    } catch (_) {
      try {
        await _storageService.createBucket(
          bucketId,
          options: const BucketOptions(public: true),
        );
      } catch (e) {
        debugPrint('Failed to ensure bucket: $e');
      }
    }
  }

  Future<void> loadNotes() async {
    isLoading.value = true;
    try {
      final data = await _noteProvider.getNotes();
      final enriched = await _attachImageUrls(data);
      notes.assignAll(enriched);
    } catch (e) {
      Get.snackbar(
        'Error',
        '${AppStrings.errorLoadingNotes}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNote(NoteModel note) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text('${AppStrings.deleteConfirm} "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (note.imagePath != null && note.imagePath!.isNotEmpty) {
          unawaited(_storageService.deleteFiles(bucketId, [note.imagePath!]));
        }

        await _noteProvider.deleteNote(note.id!);
        Get.snackbar(
          'Success',
          AppStrings.noteDeletedSuccess,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadNotes();
      } catch (e) {
        Get.snackbar(
          'Error',
          '${AppStrings.errorDeletingNote}: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Toggle a 'done' status in-memory for a note (UI only). Key uses id if available otherwise index fallback.
  void toggleDone(NoteModel note, {int? index}) {
    final key = (note.id != null) ? note.id.toString() : (index?.toString() ?? note.hashCode.toString());
    final current = doneStatus[key] == true;
    doneStatus[key] = !current;
  }

  /// Read in-memory done state
  bool isDone(NoteModel note, {int? index}) {
    final key = (note.id != null) ? note.id.toString() : (index?.toString() ?? note.hashCode.toString());
    return doneStatus[key] == true;
  }

  Future<void> goToForm({NoteModel? note}) async {
    // ensure any previous form controller instance is removed so the form reads arguments correctly
    try {
      if (Get.isRegistered<NoteFormController>()) Get.delete<NoteFormController>();
    } catch (_) {}

    final result = await Get.toNamed(Routes.NOTE_FORM, arguments: note);

    if (result != null) {
      await loadNotes();

      if (result is String && result.isNotEmpty) {
        Get.snackbar(
          'Success',
          result,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<List<NoteModel>> _attachImageUrls(List<NoteModel> data) async {
    return Future.wait(
      data.map((note) async {
        if (note.imagePath == null || note.imagePath!.isEmpty) {
          return note.copyWith(clearImage: true);
        }

        try {
          final url = _storageService.getPublicUrl(bucketId, note.imagePath!);
          return note.copyWith(imageUrl: url, imagePath: note.imagePath);
        } catch (e) {
          debugPrint('Error generating image URL for note ${note.id}: $e');
          return note;
        }
      }),
    );
  }
}