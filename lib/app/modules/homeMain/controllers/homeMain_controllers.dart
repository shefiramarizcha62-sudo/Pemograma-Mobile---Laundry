import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/homeMain_repository.dart';

class HomeMainController extends GetxController {
  final HomeMainRepository repo = Get.find<HomeMainRepository>();

  var produkLaundry = <String>[].obs;
  var filteredProduk = <String>[].obs;
  var isLoading = false.obs;
  var downloadProgress = 0.0.obs;
  var searchQuery = ''.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    repo.testDioPerformance();
    fetchProductsWithProgress();

    searchController.addListener(() {
      searchProduk(searchController.text);
    });
  }

  Future<void> fetchProductsWithProgress() async {
    isLoading(true);
    final products = await repo.fetchProductsWithProgress((progress) {
      downloadProgress(progress);
    });
    produkLaundry.assignAll(products);
    filteredProduk.assignAll(products);
    isLoading(false);
    downloadProgress(0.0);
  }

  void searchProduk(String query) {
    searchQuery(query);
    filteredProduk.assignAll(
      produkLaundry
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList(),
    );
  }

  void clearSearch() {
    searchController.clear();
    searchQuery('');
    filteredProduk.assignAll(produkLaundry);
  }

  void goToHome() {
    Get.toNamed('/home'); // ke halaman Notes + Todo
  }
}
