
import 'package:get/get.dart';
import 'package:my_app/app/modules/todo/controllers/todo_controller.dart';

class TodoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TodoController>(
      () => TodoController(),
      fenix: true,
    );
  }
}
