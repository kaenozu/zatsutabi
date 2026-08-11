import 'package:url_launcher/url_launcher.dart';

import '../models/poi.dart';

class MapsLauncher {
  Future<bool> open(Poi poi) => launchUrl(
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${poi.latitude},${poi.longitude}',
    ),
    mode: LaunchMode.externalApplication,
  );
}
