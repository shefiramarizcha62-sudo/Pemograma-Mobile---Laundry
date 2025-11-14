//buat ngepush komen ini 
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/supabase_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    //SupabaseService
    Get.lazyPut<SupabaseService>(() => SupabaseService());

    //daftarkan AuthProvider
    Get.lazyPut<AuthProvider>(() => AuthProvider());

    // AuthController
    Get.lazyPut<AuthController>(() => AuthController());
  }
}