import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../data/models/todo_model.dart';
import '../../../data/providers/todo_provider.dart';
import '../../../routes/app_pages.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/services/notification_handler.dart';

class TodoController extends GetxController {
  // ==========================
  // Dependencies
  // ==========================
  final TodoProvider _todoProvider = Get.find();
  final NotificationProvider _notificationProvider = Get.find();
  final NotificationHandler _notificationHandler = Get.find();

  // ==========================
  // State
  // ==========================
  final todos = <TodoModel>[].obs;
  final isLoading = true.obs;

  static const String _moduleName = 'Services';

  @override
  void onInit() {
    super.onInit();
    loadTodos();
  }

  // ==========================
  // Load Data
  // ==========================
  Future<void> loadTodos() async {
    isLoading.value = true;
    try {
      final data = _todoProvider.getTodos();
      todos.assignAll(data);
    } catch (e) {
      _showError('Failed to load services: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================
  // Toggle Complete / Uncomplete
  // ==========================
  Future<void> toggleTodo(TodoModel todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);

    try {
      await _todoProvider.updateTodo(updated);

      final index = todos.indexWhere((item) => item.id == todo.id);
      if (index != -1) {
        todos[index] = updated;
      }

      final title = updated.isCompleted
          ? '$_moduleName Completed'
          : '$_moduleName Uncompleted';

      final body =
          '"${todo.title}" marked as ${updated.isCompleted ? "Completed" : "Uncompleted"}';

      _notify(title, body);
    } catch (e) {
      _showError('Failed to update services: $e');
    }
  }

  // ==========================
  // Delete Service
  // ==========================
  Future<void> deleteTodo(TodoModel todo) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text('${AppStrings.deleteConfirm} "${todo.title}"?'),
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

    if (confirm != true) return;

    try {
      await _todoProvider.deleteTodo(todo.id);
      todos.removeWhere((item) => item.id == todo.id);

      _notify(
        '$_moduleName Deleted',
        '"${todo.title}" has been removed',
      );

      Get.snackbar(
        'Success',
        AppStrings.todoDeletedSuccess,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _showError('Failed to delete services: $e');
    }
  }

  // ==========================
  // Add / Update From Form
  // ==========================
  Future<void> goToForm({TodoModel? todo}) async {
    final result = await Get.toNamed(Routes.TODO_FORM, arguments: todo);
    if (result == null || result is! String || result.isEmpty) return;

    await loadTodos();

    Get.snackbar(
      'Success',
      result,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // 🔔 Notif berbeda untuk ADD vs UPDATE
    final title = todo == null ? 'New Services!' : '$_moduleName Updated';
    final body = result;

    _notify(title, body);
  }

  // ==========================
  // 🔔 Notification Helper
  // ==========================
  Future<void> _notify(String title, String body) async {
    _notificationProvider.log(
      title: title,
      body: body,
      type: 'local',
    );

    await _notificationHandler.showNotification(
      title: title,
      body: body,
      payload: Routes.TODO_LIST,
    );
  }

  // ==========================
  // Error Helper
  // ==========================
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
