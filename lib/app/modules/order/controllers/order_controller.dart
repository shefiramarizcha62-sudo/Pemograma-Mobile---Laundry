import 'package:get/get.dart';

class OrderController extends GetxController {
  RxString serviceType = ''.obs;

  @override
  void onInit() {
    serviceType.value = Get.arguments ?? 'Tidak ada data';
    super.onInit();
  }
}
