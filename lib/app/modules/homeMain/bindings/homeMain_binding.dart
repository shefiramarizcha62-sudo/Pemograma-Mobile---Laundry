import 'package:get/get.dart';
import '../controllers/homeMain_controllers.dart';
import '../services/homeMain_repository.dart';

class HomeMainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeMainRepository>(() => HomeMainRepository());
    Get.lazyPut<HomeMainController>(() => HomeMainController());
  }
}
