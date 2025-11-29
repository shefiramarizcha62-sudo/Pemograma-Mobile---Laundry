import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../controllers/network_location_controller.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../core/values/app_colors.dart';

class NetworkLocationView extends StatelessWidget {
  const NetworkLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NetworkLocationController>();
    final themeProvider = Get.find<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Network Location', 
          style: TextStyle(fontSize: 18)
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

            // ERROR
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

            // MAIN CONTENT
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

            // FLOATING ZOOM BUTTONS
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'network_zoom_in',
                    mini: true,
                    onPressed: controller.zoomIn,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'network_zoom_out',
                    mini: true,
                    onPressed: controller.zoomOut,
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'network_center',
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

  // ====================== HEADER + KOORDINAT ======================
  Widget _buildCoordinateDisplay(
    NetworkLocationController controller,
    ThemeProvider themeProvider,
    ThemeData theme,
    ) {
      final primaryColor = themeProvider.isDarkMode
        ? AppColors.darkIcon
        : theme.colorScheme.primary;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        padding: const EdgeInsets.all(16.0),


        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
            ? Colors.black.withOpacity(0.45)    // DARK MODE → hitam semi
            : Colors.white.withOpacity(0.95), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
          ),
        
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.currentPosition != null) ...[

            // ================= HEADER EMAIL & LOKASI =================
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

                      const SizedBox(height: 2),

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

                
            // ============================================================
            const SizedBox(height: 16),

              _buildCoordinateRow(
                'Latitude',
                controller.latitude?.toStringAsFixed(6) ?? 'N/A',
                Icons.north,
                themeProvider,
                theme,
              ),
              const SizedBox(height: 8),

              _buildCoordinateRow(
                'Longitude',
                controller.longitude?.toStringAsFixed(6) ?? 'N/A',
                Icons.east,
                themeProvider,
                theme,
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.4)),
              const SizedBox(height: 12),

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
                      theme
                    ),
                  ),
                ],
              ),

              if (controller.speed != null && controller.speed! > 0) ...[
                const SizedBox(height: 8),
                _buildInfoCard(
                  'Speed',
                  '${controller.speed?.toStringAsFixed(1) ?? 'N/A'} m/s',
                  Icons.speed,
                    themeProvider,
                    theme,
                ),
              ],

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
                child: Center(
                  child: Text(
                    'Tidak ada data lokasi',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }

  // ==================== ROW KOORDINAT ======================
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
        Icon(icon, 
        size: 20, 
        color: primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: Get.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  )),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: Get.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy, 
            size: 20,
            color: primaryColor, 
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

  // ====================== INFO CARD ======================
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
          Icon(icon, 
          size: 20, 
          color: primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
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
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== MAP ======================
  Widget _buildOpenStreetMap(NetworkLocationController controller) {
    if (controller.currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Menunggu data lokasi...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.getCurrentPosition,
              icon: const Icon(Icons.location_searching),
              label: const Text('Dapatkan Lokasi'),
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
            onMapEvent: (event) {
              if (event is MapEventMove && controller.isMapControllerReady) {
                final camera = controller.mapController.camera;
                controller.updateMapCenter(camera.center, camera.zoom);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mobile.modul5',
              maxZoom: 19,
              retinaMode: MediaQuery.of(Get.context!).devicePixelRatio > 1.0,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(controller.latitude!, controller.longitude!),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white),
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap'),
                TextSourceAttribution('Contributors'),
              ],
            )
          ],
        );
      } catch (e) {
        if (kDebugMode) {
          print("Map error: $e");
        }
        return const Center(child: Text("Error loading map"));
      }
    });
  }
}
