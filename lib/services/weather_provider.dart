abstract interface class WeatherProvider {
  Future<bool?> isOutdoorFriendly(double latitude, double longitude);
}

class NoWeatherProvider implements WeatherProvider {
  const NoWeatherProvider();

  @override
  Future<bool?> isOutdoorFriendly(double latitude, double longitude) async =>
      null;
}
