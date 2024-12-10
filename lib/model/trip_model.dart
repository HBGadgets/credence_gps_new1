class TripLog {
  final int deviceId;
  final double distance;

  TripLog({required this.deviceId, required this.distance});

  factory TripLog.fromJson(Map<String, dynamic> json) {
    return TripLog(
      deviceId: json['deviceId'],
      distance: json['distance'] / 1000,
    );
  }
}
