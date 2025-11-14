import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/homeMain/bindings/homeMain_binding.dart';
import '../modules/homeMain/views/homeMain_view.dart';
import '../modules/note/bindings/note_binding.dart';
import '../modules/note/views/note_list_view.dart';
import '../modules/note/views/note_form_view.dart';
import '../modules/todo/bindings/todo_binding.dart';
import '../modules/todo/views/todo_list_view.dart';
import '../modules/todo/views/todo_form_view.dart';


part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    // Auth
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),

    // HomeMain
    GetPage(
      name: Routes.HOME_MAIN,
      page: () => const HomeMainView(),
      binding: HomeMainBinding(),
    ),

    // Home
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),

    // Note
    GetPage(
      name: Routes.NOTE_LIST,
      page: () => const NoteListView(),
      binding: NoteBinding(),
    ),
    GetPage(
      name: Routes.NOTE_FORM,
      page: () => NoteFormView(),
      binding: NoteBinding(),
    ),

     GetPage(
       name: Routes.TODO_LIST,
       page: () => const TodoListView(),
       binding: TodoBinding(),
     ),
     GetPage(
       name: Routes.TODO_FORM,
       page: () => TodoFormView(),
       binding: TodoBinding(),
     ),
  ];
}