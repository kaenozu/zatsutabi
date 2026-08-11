import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Time budget for a single position fix. Without one, a hung
  /// getCurrentPosition() would block the suggestion flow forever.
  static const _fixTimeout = Duration(seconds: 15);

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable(serviceDisabled: true);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable(denied: true);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable(permanentlyDenied: true);
    }
    try {
          // ignore: deprecated_member_use
          return await Geolocator.getCurrentPosition(
            // ignore: deprecated_member_use
            timeLimit: _fixTimeout,
          );
    } on TimeoutException {
      throw const LocationUnavailable(timeout: true);
    } catch (_) {
      throw const LocationUnavailable(serviceDisabled: true);
    }
  }
}

class LocationUnavailable implements Exception {
  const LocationUnavailable({
    this.permanentlyDenied = false,
    this.serviceDisabled = false,
    this.denied = false,
    this.timeout = false,
  });

  final bool permanentlyDenied;

  /// Location services (GPS) are switched off at the OS level.
  final bool serviceDisabled;

  /// The user denied the permission prompt during this request.
  final bool denied;

  /// The position fix did not complete within the timeout.
  final bool timeout;
}
