import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../controllers/gps_location_controller.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../core/values/app_colors.dart';

class GpsLocationView extends StatelessWidget {
  const GpsLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GpsLocationController>();
    final themeProvider = Get.find<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPS Location',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshPosition,
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: controller.openAppSettings,
            tooltip: 'Open Settings',
          ),
        ],
      ),

      // BACKGROUND GRADIENT / TRANSPARAN GLOBAL
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.isDarkMode
              ? const LinearGradient(
                  colors: [
                  Color(0xFF000000),
                  Color(0xFF1A1A1A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [
                Color(0xFF344D7D),
                Color(0xFFD6EFFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.10, 0.80],
            ),
      ),
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mendapatkan lokasi...'),
                ],
              ),
            );
          }

          if (controller.errorMessage.isNotEmpty) {
            final errorAction = controller.getErrorAction();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: errorAction['action'] as VoidCallback?,
                      icon: Icon(errorAction['icon'] as IconData),
                      label: Text(errorAction['label'] as String),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  _buildCoordinateDisplay(
                    controller,
                    themeProvider,
                    theme,
                  ),
                  Expanded(child: _buildOpenStreetMap(controller)),
                ],
              ),

              // FAB ZOOM & CENTER
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'gps_zoom_in',
                      mini: true,
                      onPressed: controller.zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'gps_zoom_out',
                      mini: true,
                      onPressed: controller.zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'gps_center',
                      mini: true,
                      onPressed: controller.moveToCurrentPosition,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // =====================================================================
  // CARD UTAMA (EMAIL, DETAIL LOCATION, LAT / LNG / AKURASI / ALT / WAKTU)
  // =====================================================================
  Widget _buildCoordinateDisplay(
    GpsLocationController controller,
    ThemeProvider themeProvider,
    ThemeData theme,
  ) {
    final primaryColor = themeProvider.isDarkMode
        ? AppColors.darkIcon
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
          ? Colors.black.withOpacity(0.45)    // DARK MODE → hitam semi
          : Colors.white.withOpacity(0.95), // transparan biar gradient keliatan
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.currentPosition != null) ...[
            // ==========================
            // EMAIL & DETAIL LOCATION
            // ==========================
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 22,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.userEmail.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor, // EMAIL
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),  // ★ Bikin rata kiri dengan email
                    child:Text(
                      controller.locationDetail.value.isEmpty
                        ? 'Lokasi ...'
                        : controller.locationDetail.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor, // DETAIL LOCATION
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ==========================
            // LATITUDE
            // ==========================
            _buildCoordinateRow(
              'Latitude',
              controller.latitude?.toStringAsFixed(6) ?? 'N/A',
              Icons.north, // panah ke atas
              themeProvider,
              theme,
            ),
            const SizedBox(height: 8),

            // ==========================
            // LONGITUDE
            // ==========================
            _buildCoordinateRow(
              'Longitude',
              controller.longitude?.toStringAsFixed(6) ?? 'N/A',
              Icons.east, // panah ke samping
              themeProvider,
              theme,
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 12),

            // ==========================
            // AKURASI + ALTITUDE
            // ==========================
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Akurasi',
                    '${controller.accuracy?.toStringAsFixed(1) ?? 'N/A'} m',
                    Icons.my_location,
                    themeProvider,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    'Altitude',
                    '${controller.altitude?.toStringAsFixed(1) ?? 'N/A'} m',
                    Icons.height,
                    themeProvider,
                    theme,
                  ),
                ),
              ],
            ),

      

            // ==========================
            // WAKTU
            // ==========================
            if (controller.timestamp != null) ...[
              const SizedBox(height: 8),
              _buildInfoCard(
                'Waktu',
                DateFormat('HH:mm:ss').format(controller.timestamp!),
                Icons.access_time,
                themeProvider,
                theme,
              ),
            ],
          ] else ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Tidak ada data lokasi',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // ROW UNTUK LAT / LNG (ikon + teks label + value + tombol copy)
  // ==============================================================
  Widget _buildCoordinateRow(
    String label,
    String value,
    IconData icon,
    ThemeProvider themeProvider,
    ThemeData theme,
  ) {
    final primaryColor = themeProvider.isDarkMode
        ? AppColors.darkIcon
        : theme.colorScheme.primary;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryColor, // ikon panah LAT / LNG
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: primaryColor, // teks "Latitude" / "Longitude"
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: Get.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: primaryColor, // value angka LAT / LNG
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy,
            size: 20,
            color: primaryColor, // ikon salin
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            Get.snackbar(
              'Copied',
              '$label: $value',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
      ],
    );
  }

  // ==============================================================
  // CARD KECIL UNTUK AKURASI / ALTITUDE / SPEED / WAKTU
  // ==============================================================
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    ThemeProvider themeProvider,
    ThemeData theme,
  ) {
    final primaryColor = themeProvider.isDarkMode
        ? AppColors.darkIcon
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryColor, // ikon akurasi / altitude / waktu / speed
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, // "Akurasi" / "Altitude" / "Speed" / "Waktu"
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor, // semua value (angka + waktu)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // OPENSTREETMAP VIEW
  // ==============================
  Widget _buildOpenStreetMap(GpsLocationController controller) {
    if (controller.currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Menunggu data lokasi...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      try {
        return FlutterMap(
          mapController: controller.mapController,
          options: MapOptions(
            initialCenter: controller.mapCenter,
            initialZoom: controller.mapZoom,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mobile.modul5',
              maxZoom: 19,
            ),
            if (controller.currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      controller.latitude!,
                      controller.longitude!,
                    ),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error loading map: $e');
        }
        return const Center(child: Text('Error loading map'));
      }
    });
  }
}
