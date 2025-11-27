import 'package:dio/dio.dart';
import 'package:my_app/app/data/services/api_service.dart';

// ganti dengan nama projectmu
class HomeMainRepository {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> fetchProductsWithProgress(
    Function(double) onProgress,
  ) async {
    final response = await _api.get(
      '',
      onReceiveProgress: (received, total) {
        if (total != -1) onProgress(received / total);
      },
    );

    final List<dynamic> products = response.data;

    print("=== DEBUG RESPONSE ANDROID ===");
    for (var item in products.take(4)) {
      print(item);
    }
    print("==============================");

    // Ambil hanya 4 pertama
    final limited = products.take(4).toList();

    // Kembalikan hanya nama produk
    return limited.map<Map<String, dynamic>>((p) {
      return {
        'nama': p['nama'] ?? 'Tanpa Nama',
      };
    }).toList();
  }

  Future<void> testDioPerformance() async {
    final stopwatch = Stopwatch()..start();
    print('🟣 [DIO] Memulai request test...');

    try {
      final response = await _api.get('layanan');
      stopwatch.stop();

      print('==============================');
      print('🌐 DIO TEST RESULT');
      print('Status Code : ${response.statusCode}');
      print('Response Time: ${stopwatch.elapsedMilliseconds} ms');
      print('Data Length  : ${(response.data as List).length}');
      print('==============================');
    } on DioException catch (e) {
      print('⚠️ [DIO ERROR] ${e.message}');
    }
  }
}