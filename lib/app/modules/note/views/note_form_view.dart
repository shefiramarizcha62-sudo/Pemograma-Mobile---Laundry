import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/values/app_strings.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/note_provider.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/note_controller.dart';

class NoteFormController extends GetxController {
  final NoteProvider _noteProvider = Get.find();
  final StorageService _storageService = Get.find();
  final AuthProvider _authProvider = Get.find();
  final ImagePicker _picker = ImagePicker();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final isFormValid = false.obs;

  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  final selectedImage = Rxn<XFile>();
  final selectedImageBytes = Rxn<Uint8List>();
  final existingImageUrl = RxnString();

  NoteModel? note;
  bool _removeExistingImage = false;

  bool get isEditing => note != null;
  bool get hasPreviewImage =>
      selectedImage.value != null ||
      selectedImageBytes.value != null ||
      existingImageUrl.value != null;

  @override
  void onInit() {
    super.onInit();
    note = Get.arguments as NoteModel?;
    if (note != null) {
      titleController.text = note!.title;
      contentController.text = note!.content;

      if (note!.imageUrl != null) {
        existingImageUrl.value = note!.imageUrl;
      } else if (note!.imagePath != null && note!.imagePath!.isNotEmpty) {
        try {
          existingImageUrl.value = _storageService.getPublicUrl(
            NoteController.bucketId,
            note!.imagePath!,
          );
        } catch (e) {
          debugPrint('Unable to load existing image URL: $e');
        }
      }
    }
    // update form valid state when fields change
    titleController.addListener(_updateFormValid);
    contentController.addListener(_updateFormValid);
    _updateFormValid();
  }

  /// Initialize the controller with an existing note (used when opening the form as a bottom sheet)
  void initForEdit(NoteModel? initialNote) {
    if (initialNote == null) return;

    note = initialNote;
    titleController.text = note!.title;
    contentController.text = note!.content;

    if (note!.imageUrl != null) {
      existingImageUrl.value = note!.imageUrl;
    } else if (note!.imagePath != null && note!.imagePath!.isNotEmpty) {
      try {
        existingImageUrl.value = _storageService.getPublicUrl(
          NoteController.bucketId,
          note!.imagePath!,
        );
      } catch (e) {
        debugPrint('Unable to load existing image URL: $e');
      }
    }

    _updateFormValid();
  }

  void _updateFormValid() {
    final titleOk = titleController.text.trim().isNotEmpty;
    final contentOk = contentController.text.trim().isNotEmpty;
    isFormValid(titleOk && contentOk);
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    titleController.removeListener(_updateFormValid);
    contentController.removeListener(_updateFormValid);
    super.onClose();
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterNoteTitle;
    }
    return null;
  }

  String? validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterNoteContent;
    }
    return null;
  }

  Future<void> pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (file != null) {
        selectedImage.value = file;
        existingImageUrl.value = null;
        _removeExistingImage = false;

        if (kIsWeb) {
          selectedImageBytes.value = await file.readAsBytes();
        } else {
          selectedImageBytes.value = null;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removeImage() {
    selectedImage.value = null;
    selectedImageBytes.value = null;
    if (isEditing && note?.imagePath != null) {
      _removeExistingImage = true;
    }
    existingImageUrl.value = null;
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final trimmedTitle = titleController.text.trim();
    final trimmedContent = contentController.text.trim();

    final oldImagePath = note?.imagePath;
    String? imagePath = oldImagePath;
    String? uploadedImagePath;
    var deleteOldAfterSuccess = false;

    try {
      if (_removeExistingImage) {
        imagePath = null;
        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          deleteOldAfterSuccess = true;
        }
      }

      if (selectedImage.value != null) {
        uploadedImagePath = await _uploadSelectedImage();
        imagePath = uploadedImagePath;
        if (oldImagePath != null &&
            oldImagePath.isNotEmpty &&
            oldImagePath != uploadedImagePath) {
          deleteOldAfterSuccess = true;
        }
      }

      String successMessage;
      if (isEditing) {
        final updated = note!.copyWith(
          title: trimmedTitle,
          content: trimmedContent,
          imagePath: imagePath,
          clearImage: imagePath == null,
        );
        await _noteProvider.updateNote(updated);
        successMessage = AppStrings.noteUpdatedSuccess;
      } else {
        final newNote = NoteModel(
          title: trimmedTitle,
          content: trimmedContent,
          imagePath: imagePath,
        );
        await _noteProvider.createNote(newNote);
        successMessage = AppStrings.noteAddedSuccess;
      }

      if (deleteOldAfterSuccess &&
          oldImagePath != null &&
          oldImagePath.isNotEmpty) {
        unawaited(_deleteImage(oldImagePath));
      }

      try {
        final listController = Get.find<NoteController>();
        // ignore: unawaited_futures
        listController.loadNotes();
      } catch (_) {}

      Get.back(result: successMessage);
    } catch (e) {
      if (uploadedImagePath != null && uploadedImagePath != oldImagePath) {
        unawaited(_deleteImage(uploadedImagePath));
      }

      Get.snackbar(
        'Error',
        '${AppStrings.errorSavingNote}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _uploadSelectedImage() async {
    final file = selectedImage.value;
    if (file == null) {
      throw StateError('No image selected');
    }

    final extension = _fileExtension(file);
    final userId = _authProvider.currentUser?.id ?? 'public';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$timestamp$extension';

    if (kIsWeb) {
      final bytes = selectedImageBytes.value ?? await file.readAsBytes();
      await _storageService.uploadBytes(
        NoteController.bucketId,
        storagePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
    } else {
      await _storageService.uploadFile(
        NoteController.bucketId,
        storagePath,
        File(file.path),
        fileOptions: const FileOptions(upsert: true),
      );
    }

    return storagePath;
  }

  Future<void> _deleteImage(String path) async {
    try {
      await _storageService.deleteFiles(NoteController.bucketId, [path]);
    } catch (e) {
      debugPrint('Failed to delete image "$path": $e');
    }
  }

  String _fileExtension(XFile file) {
    final name = file.name.isNotEmpty ? file.name : file.path;
    final ext = p.extension(name);
    if (ext.isEmpty) {
      return '.jpg';
    }
    return ext;
  }
}

class NoteFormView extends StatelessWidget {
  /// When provided, the form initializes for editing the passed [initialNote].
  final NoteModel? initialNote;

  NoteFormView({super.key, this.initialNote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // create controller instance for this view (fresh instance should be deleted by caller if needed)
    final controller = Get.put(NoteFormController());

    // If initialNote is provided (edit case opened as bottom sheet), initialize controller state
    if (initialNote != null && (controller.note == null || controller.note?.id != initialNote!.id)) {
      controller.initForEdit(initialNote);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          controller.isEditing ? AppStrings.editNote : AppStrings.addNote,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
          child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // large white neumorphic card containing the input sections
              Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nama Customer input in its own soft card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Obx(() => TextFormField(
                              controller: controller.titleController,
                              decoration: InputDecoration(
                                labelText: AppStrings.noteTitle,
                                prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                                border: InputBorder.none,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: controller.validateTitle,
                              enabled: !controller.isLoading.value,
                            )),
                      ),
                      const SizedBox(height: 12),

                      // Berat input in own soft card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Obx(() => TextFormField(
                              controller: controller.contentController,
                              decoration: InputDecoration(
                                labelText: AppStrings.noteContent,
                                prefixIcon: Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary),
                                suffixText: 'kg',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                              validator: controller.validateContent,
                              enabled: !controller.isLoading.value,
                            )),
                      ),
                      const SizedBox(height: 12),

                      // Image selector + preview in a single row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // left: pick button area (flexible)
                            Expanded(
                              child: GestureDetector(
                                onTap: controller.isLoading.value ? null : controller.pickImage,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.image_outlined, color: theme.colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppStrings.addImage, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                            Obx(() => Text(
                                                  controller.hasPreviewImage ? AppStrings.changeImage : AppStrings.addImage,
                                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // right: preview box
                            const SizedBox(width: 12),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Obx(() {
                                  final pickedFile = controller.selectedImage.value;
                                  final pickedBytes = controller.selectedImageBytes.value;
                                  final existingUrl = controller.existingImageUrl.value;
                                  if (pickedBytes != null) {
                                    return Image.memory(pickedBytes, fit: BoxFit.cover);
                                  } else if (pickedFile != null && !kIsWeb) {
                                    return Image.file(File(pickedFile.path), fit: BoxFit.cover);
                                  } else if (existingUrl != null) {
                                    return Image.network(existingUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink());
                                  }
                                  return Icon(Icons.photo_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4));
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 18),
              Obx(() {
                final enabled = controller.isFormValid.value && !controller.isLoading.value;
                return FilledButton(
                  onPressed: enabled ? controller.submitForm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: enabled ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.35),
                    foregroundColor: enabled ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimary.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          controller.isEditing ? AppStrings.updateNote : AppStrings.saveNote,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// _ImageAttachmentSection and _Placeholder removed — image picker is integrated directly in the form UI above.
