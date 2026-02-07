class NepalLocation {
  final String district;
  final String province;
  final String hq;
  final double lat;
  final double lng;

  NepalLocation({
    required this.district,
    required this.province,
    required this.hq,
    required this.lat,
    required this.lng,
  });

  factory NepalLocation.fromJson(Map<String, dynamic> json) {
    return NepalLocation(
      district: json['district'],
      province: json['province'],
      hq: json['hq'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'province': province,
      'hq': hq,
      'lat': lat,
      'lng': lng,
    };
  }

  String get displayName => "$district, $province";

  @override
  String toString() => displayName;
}
