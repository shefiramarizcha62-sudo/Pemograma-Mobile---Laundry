import 'package:get/get.dart';

// 🔹 Import module lain
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/note/bindings/note_binding.dart';
import '../modules/note/views/note_list_view.dart';
import '../modules/note/views/note_form_view.dart';
import '../modules/todo/binding/todo_binding.dart';
import '../modules/todo/views/todo_list_view.dart';
import '../modules/todo/views/todo_form_view.dart';

// 🔹 Tambahan: import untuk homeMain FIRA
import '../modules/homeMain/bindings/homeMain_binding.dart';
import '../modules/homeMain/views/homeMain_view.dart';

part of 'app_page.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    // 🔹 Login & Register
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),

    // 🔹 Tambahan: HomeMain
    GetPage(
      name: _Paths.HOME_MAIN,
      page: () => const HomeMainView(),
      binding: HomeMainBinding(),
    ),

    // 🔹 Home utama (isi notes & todo)
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),

    