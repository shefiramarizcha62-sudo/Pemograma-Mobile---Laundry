import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/auth_provider.dart';
import '../services/homeMain_repository.dart';

class HomeMainController extends GetxController {
  final HomeMainRepository repo = Get.find<HomeMainRepository>();
  final AuthProvider _authProvider = Get.find(); // pastikan AuthProvider sudah didaftarkan di binding auth

  var produkLaundry = <String>[].obs;
  var filteredProduk = <String>[].obs;
  var isLoading = false.obs;
  var downloadProgress = 0.0.obs;
  var searchQuery = ''.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // inisialisasi data
    fetchProductsWithProgress();
    searchController.addListener(() {
      searchProduk(searchController.text);
    });
  }

  // Wrapper yang dipanggil dari view untuk reload/pull-to-refresh
  Future<void> fetchProductsWithProgress() async {
    try {
      isLoading(true);
      final products = await repo.fetchProductsWithProgress((progress) {
        downloadProgress(progress);
      });
      produkLaundry.assignAll(products);
      filteredProduk.assignAll(products);
    } catch (e) {
      // tangani error sesuai kebutuhan
      print('[HomeMain] fetch error: $e');
    } finally {
      isLoading(false);
      downloadProgress(0.0);
    }
  }

  // Untuk compatibilty: method yang tadi dipanggil view
  Future<void> fetchDataFromApi() async => await fetchProductsWithProgress();

  void searchProduk(String query) {
    searchQuery(query);
    if (query.isEmpty) {
      filteredProduk.assignAll(produkLaundry);
    } else {
      filteredProduk.assignAll(
        produkLaundry
            .where((p) => p.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery('');
    filteredProduk.assignAll(produkLaundry);
  }

  // Navigasi ke halaman Home (notes & todos)
  void goToHome() {
    Get.toNamed('/home'); // pastikan rute '/home' terdaftar di app_pages
  }

  // Getter untuk email user (dipakai di popup profile)
  String? get userEmail => _authProvider.currentUser?.email;
}
