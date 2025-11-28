import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart'; // <— WAJIB
import '../../../data/services/location_service.dart';
import '../../../data/providers/auth_provider.dart';


/// Controller untuk GPS Location Tracker
/// Menggunakan GPS dengan akurasi tinggi
class GpsLocationController extends GetxController {
  final LocationService _locationService = LocationService();
  final AuthProvider _auth = Get.find();

  // Observables
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isTracking = false.obs;
  final Rx<LocationPermission> _permissionStatus =
      LocationPermission.denied.obs;
    

  // NEW — Email user & detail alamat
  RxString userEmail = 'example@gmail.com'.obs;
  RxString locationDetail = ''.obs;

  // FlutterMap Controller
  MapController? _mapController;
  bool _isDisposed = false;

  // Map center position dan zoom
  final Rx<LatLng> _mapCenter = Rx<LatLng>(
    const LatLng(-6.2088, 106.8456), // Jakarta default
  );
  final RxDouble _mapZoom = 15.0.obs;

  // Stream subscription
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  Position? get currentPosition => _currentPosition.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isTracking => _isTracking.value;
  LocationPermission get permissionStatus => _permissionStatus.value;
  MapController get mapController {
    if (_mapController == null || _isDisposed) {
      try {
        _mapController?.dispose();
      } catch (_) {}
      _mapController = MapController();
      _isDisposed = false;
    }
    return _mapController!;
  }

  bool get isMapControllerReady => _mapController != null && !_isDisposed;
  LatLng get mapCenter => _mapCenter.value;
  double get mapZoom => _mapZoom.value;

  // Computed values
  double? get latitude => _currentPosition.value?.latitude;
  double? get longitude => _currentPosition.value?.longitude;
  double? get accuracy => _currentPosition.value?.accuracy;
  double? get altitude => _currentPosition.value?.altitude;
  double? get speed => _currentPosition.value?.speed;
  DateTime? get timestamp => _currentPosition.value?.timestamp;

  @override
  void onInit() {
    super.onInit();
    userEmail.value = _auth.currentUser?.email ?? 'Unknown User';
    _isDisposed = false;

    try {
      _mapController?.dispose();
    } catch (_) {}

    _mapController = MapController();
    _initializeLocation();
  }

  @override
  void onClose() {
    _isDisposed = true;
    _stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      _mapController?.dispose();
    } catch (_) {
      if (kDebugMode) {
        print('Error disposing map controller');
      }
    } finally {
      _mapController = null;
    }

    super.onClose();
  }

  bool _canUseMapController() {
    return !_isDisposed && _mapController != null;
  }

  // -----------------------------
  // ⭐ NEW: Reverse Geocoding
  // -----------------------------
  Future<void> updateLocationDetail() async {
    if (_currentPosition.value == null) {
      locationDetail.value = '';
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        _currentPosition.value!.latitude,
        _currentPosition.value!.longitude,
      );

      final p = placemarks.first;

      locationDetail.value =
          '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}';
    } catch (e) {
      locationDetail.value = 'Lokasi tidak ditemukan';
    }
  }

  // -----------------------------------
  //  INITIALIZE GPS  
  // -----------------------------------
  Future<void> _initializeLocation() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      bool isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      _permissionStatus.value = await _locationService.checkPermission();

      if (_permissionStatus.value == LocationPermission.denied ||
          _permissionStatus.value == LocationPermission.deniedForever) {
        await requestPermission();
      }

      await getCurrentPosition();

      _isLoading.value = false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  // -----------------------------------
  // REQUEST PERMISSION
  // -----------------------------------
  Future<void> requestPermission() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      bool isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        throw Exception('GPS tidak aktif. Aktifkan di pengaturan.');
      }

      bool granted = await _locationService.requestPermission(requireGps: true);
      _permissionStatus.value = await _locationService.checkPermission();

      if (!granted) {
        throw PermissionDeniedException('Location permission denied');
      }

      await getCurrentPosition();

      _isLoading.value = false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }
     Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
  // -----------------------------------
  // GET CURRENT POSITION (GPS ONLY)
  // -----------------------------------
  Future<void> getCurrentPosition() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      bool isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        throw Exception('GPS tidak aktif');
      }

      bool hasPermission = await _locationService.isPermissionGranted();
      if (!hasPermission) {
        throw PermissionDeniedException('Location permission denied');
      }

      Position? position =
          await _locationService.getCurrentPosition(useGps: true);

      if (position == null) {
        throw Exception('Failed to get current position');
      }

      _currentPosition.value = position;

      // 🔥 UPDATE DETAIL ALAMAT SEKALIGUS
      await updateLocationDetail();  // <— HERE

      _updateMapPosition(position);
      _isLoading.value = false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  Future<void> getLastKnownPosition() async {
    try {
      Position? position = await _locationService.getLastKnownPosition();
      if (position != null) {
        _currentPosition.value = position;
        await updateLocationDetail(); // <—
        _updateMapPosition(position);
      }
    } catch (_) {}
  }

  // -----------------------------------
  // START TRACKING (STREAM)
  // -----------------------------------
  Future<void> startTracking() async {
    try {
      bool isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        throw Exception('GPS tidak aktif');
      }

      bool hasPermission = await _locationService.isPermissionGranted();
      if (!hasPermission) {
        hasPermission =
            await _locationService.requestPermission(requireGps: true);
      }

      if (!hasPermission) {
        throw PermissionDeniedException('Permission denied');
      }

      _isTracking.value = true;
      _errorMessage.value = '';

      Stream<Position>? stream = _locationService.getPositionStream(
        useGps: true,
        distanceFilter: 10,
      );

      _positionSubscription?.cancel();

      _positionSubscription = stream?.listen(
        (Position pos) async {
          _currentPosition.value = pos;

          // 🔥 UPDATE ALAMAT SAAT TRACKING
          await updateLocationDetail(); // <—

          _updateMapPosition(pos);
        },
        onError: (err) {
          _errorMessage.value = err.toString();
        },
      );
    } catch (e) {
      _errorMessage.value = e.toString();
      _isTracking.value = false;
    }
  }

  void _stopTracking() {
    _isTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationService.stopPositionStream();
  }

  void stopTracking() => _stopTracking();

  void _updateMapPosition(Position position) {
    if (_isDisposed || !_canUseMapController()) return;

    final newCenter = LatLng(position.latitude, position.longitude);
    _mapCenter.value = newCenter;

    try {
      _mapController?.move(newCenter, _mapZoom.value);
    } catch (_) {}
  }

  void updateMapCenter(LatLng center, double zoom) {
    if (_isDisposed) return;
    _mapCenter.value = center;
    _mapZoom.value = zoom;
  }

  void setZoom(double zoom) {
    if (_isDisposed || !_canUseMapController()) return;

    _mapZoom.value = zoom;

    if (_currentPosition.value != null) {
      try {
        _mapController?.move(
          LatLng(
            _currentPosition.value!.latitude,
            _currentPosition.value!.longitude,
          ),
          zoom,
        );
      } catch (_) {}
    }
  }

  void zoomIn() => setZoom((_mapZoom.value + 1).clamp(3.0, 18.0));

  void zoomOut() => setZoom((_mapZoom.value - 1).clamp(3.0, 18.0));

  void moveToCurrentPosition() {
    if (_isDisposed || !_canUseMapController()) return;

    if (_currentPosition.value != null) {
      try {
        final pos = _currentPosition.value!;
        final center = LatLng(pos.latitude, pos.longitude);
        _mapController?.move(center, _mapZoom.value);
        _mapCenter.value = center;
      } catch (_) {}
    }
  }

  Future<void> refreshPosition() async => await getCurrentPosition();

  void resetMapController() {
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = MapController();
    _isDisposed = false;
  }

  Future<void> toggleTracking() async {
    if (_isTracking.value) {
      stopTracking();
    } else {
      await startTracking();
    }
  }

  /// Get error action button info berdasarkan konteks error
  Map<String, dynamic> getErrorAction() {
    final error = _errorMessage.value.toLowerCase();

    if (error.contains('disabled') ||
        error.contains('enable gps') ||
        error.contains('location services')) {
      return {
        'label': 'Aktifkan GPS',
        'icon': Icons.gps_fixed,
        'action': openLocationSettings,
      };
    }

    if (error.contains('permanently denied') ||
        error.contains('deniedforever')) {
      return {
        'label': 'Buka Pengaturan',
        'icon': Icons.settings,
        'action': openAppSettings,
      };
    }

    if (error.contains('permission')) {
      return {
        'label': 'Berikan Izin Lokasi',
        'icon': Icons.location_on,
        'action': requestPermission,
      };
    }

    if (error.contains('timeout')) {
      return {
        'label': 'Coba Lagi',
        'icon': Icons.refresh,
        'action': getCurrentPosition,
      };
    }

    return {
      'label': 'Coba Lagi',
      'icon': Icons.refresh,
      'action': getCurrentPosition,
    };
  }
}
