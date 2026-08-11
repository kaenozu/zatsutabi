import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable(permanentlyDenied: true);
    }
    return Geolocator.getCurrentPosition();
  }
}

class LocationUnavailable implements Exception {
  const LocationUnavailable({this.permanentlyDenied = false});

  final bool permanentlyDenied;
}
