import 'package:url_launcher/url_launcher.dart';

import '../models/poi.dart';

class MapsLauncher {
  Uri destinationUri(Poi poi) => Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${poi.latitude},${poi.longitude}',
  );

  Future<bool> open(Poi poi) =>
      launchUrl(destinationUri(poi), mode: LaunchMode.externalApplication);
}
