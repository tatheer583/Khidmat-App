import 'package:geolocator/geolocator.dart';
import '../models/marketplace_models.dart';

enum LocationAccess { unknown, granted, denied, deniedForever, serviceDisabled }

class LocationAccessException implements Exception {
  const LocationAccessException(this.access, this.message);
  final LocationAccess access;
  final String message;
  @override
  String toString() => message;
}

/// A foreground, single-fix location service. It never starts background tracking.
class DeviceLocationService {
  LocationAccess lastAccess = LocationAccess.unknown;

  Future<LocationAccess> checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return lastAccess = LocationAccess.serviceDisabled;
    }
    return lastAccess = _access(await Geolocator.checkPermission());
  }

  Future<SearchLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(
        LocationAccess.serviceDisabled,
        'Location services are off. Turn them on or choose your city manually.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    lastAccess = _access(permission);
    if (lastAccess != LocationAccess.granted) {
      throw LocationAccessException(
        lastAccess,
        lastAccess == LocationAccess.deniedForever
            ? 'Location permission is blocked. Enable it in app settings or choose your city manually.'
            : 'Location access was declined. You can browse by city instead.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final location = SearchLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      isDevice: true,
    );
    location.validate();
    return location;
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static LocationAccess _access(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied => LocationAccess.denied,
        _ => LocationAccess.unknown,
      };
}
