

class CityModel {
  final String name;
  final double lat;
  final double lon;
  final String country;
  final double timezone;

  CityModel({
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
    required this.timezone,
  });

  @override
  String toString() => '$name, $country';
}

class LocationService {
  static final List<CityModel> _cities = [
    // Nepal (Timezone +5.75)
    CityModel(name: 'Kathmandu', lat: 27.7172, lon: 85.3240, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Pokhara', lat: 28.2096, lon: 83.9856, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Lalitpur', lat: 27.671, lon: 85.324, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Bharatpur', lat: 27.6833, lon: 84.4333, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Biratnagar', lat: 26.45, lon: 87.2667, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Birgunj', lat: 27.0163, lon: 84.8778, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Dharan', lat: 26.8125, lon: 87.2831, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Nepalgunj', lat: 28.05, lon: 81.6167, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Itahari', lat: 26.6644, lon: 87.2717, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Hetauda', lat: 27.4277, lon: 85.0348, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Janakpur', lat: 26.7271, lon: 85.9229, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Butwal', lat: 27.7006, lon: 83.4484, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Tulsipur', lat: 28.1289, lon: 82.2972, country: 'Nepal', timezone: 5.75),
    CityModel(name: 'Siddharthanagar', lat: 27.502, lon: 83.45, country: 'Nepal', timezone: 5.75),
    
    // India (Timezone +5.5)
    CityModel(name: 'New Delhi', lat: 28.6139, lon: 77.2090, country: 'India', timezone: 5.5),
    CityModel(name: 'Mumbai', lat: 19.0760, lon: 72.8777, country: 'India', timezone: 5.5),
    CityModel(name: 'Bangalore', lat: 12.9716, lon: 77.5946, country: 'India', timezone: 5.5),
    CityModel(name: 'Chennai', lat: 13.0827, lon: 80.2707, country: 'India', timezone: 5.5),
    CityModel(name: 'Kolkata', lat: 22.5726, lon: 88.3639, country: 'India', timezone: 5.5),
    CityModel(name: 'Hyderabad', lat: 17.3850, lon: 78.4867, country: 'India', timezone: 5.5),
    CityModel(name: 'Ahmedabad', lat: 23.0225, lon: 72.5714, country: 'India', timezone: 5.5),
    CityModel(name: 'Pune', lat: 18.5204, lon: 73.8567, country: 'India', timezone: 5.5),
    CityModel(name: 'Surat', lat: 21.1702, lon: 72.8311, country: 'India', timezone: 5.5),
    CityModel(name: 'Jaipur', lat: 26.9124, lon: 75.7873, country: 'India', timezone: 5.5),
    CityModel(name: 'Lucknow', lat: 26.8467, lon: 80.9462, country: 'India', timezone: 5.5),
    CityModel(name: 'Kanpur', lat: 26.4499, lon: 80.3319, country: 'India', timezone: 5.5),
    CityModel(name: 'Nagpur', lat: 21.1458, lon: 79.0882, country: 'India', timezone: 5.5),
    CityModel(name: 'Indore', lat: 22.7196, lon: 75.8577, country: 'India', timezone: 5.5),
    CityModel(name: 'Thane', lat: 19.2183, lon: 72.9781, country: 'India', timezone: 5.5),
    CityModel(name: 'Bhopal', lat: 23.2599, lon: 77.4126, country: 'India', timezone: 5.5),
    CityModel(name: 'Visakhapatnam', lat: 17.6868, lon: 83.2185, country: 'India', timezone: 5.5),
    CityModel(name: 'Pimpri-Chinchwad', lat: 18.6298, lon: 73.7997, country: 'India', timezone: 5.5),
    CityModel(name: 'Patna', lat: 25.5941, lon: 85.1376, country: 'India', timezone: 5.5),
    CityModel(name: 'Vadodara', lat: 22.3072, lon: 73.1812, country: 'India', timezone: 5.5),
    CityModel(name: 'Ghaziabad', lat: 28.6692, lon: 77.4538, country: 'India', timezone: 5.5),
    CityModel(name: 'Ludhiana', lat: 30.9010, lon: 75.8573, country: 'India', timezone: 5.5),
    CityModel(name: 'Agra', lat: 27.1767, lon: 78.0081, country: 'India', timezone: 5.5),
    CityModel(name: 'Nashik', lat: 19.9975, lon: 73.7898, country: 'India', timezone: 5.5),
    CityModel(name: 'Faridabad', lat: 28.4089, lon: 77.3178, country: 'India', timezone: 5.5),
    CityModel(name: 'Meerut', lat: 28.9845, lon: 77.7064, country: 'India', timezone: 5.5),
    CityModel(name: 'Rajkot', lat: 22.3039, lon: 70.8022, country: 'India', timezone: 5.5),
    CityModel(name: 'Varanasi', lat: 25.3176, lon: 83.0062, country: 'India', timezone: 5.5),
    CityModel(name: 'Srinagar', lat: 34.0837, lon: 74.7973, country: 'India', timezone: 5.5),
    CityModel(name: 'Aurangabad', lat: 19.8762, lon: 75.3433, country: 'India', timezone: 5.5),
    CityModel(name: 'Dhanbad', lat: 23.7957, lon: 86.4304, country: 'India', timezone: 5.5),
    CityModel(name: 'Amritsar', lat: 31.6340, lon: 74.8723, country: 'India', timezone: 5.5),
    CityModel(name: 'Navi Mumbai', lat: 19.0330, lon: 73.0297, country: 'India', timezone: 5.5),
    CityModel(name: 'Allahabad', lat: 25.4358, lon: 81.8463, country: 'India', timezone: 5.5),
    CityModel(name: 'Ranchi', lat: 23.3441, lon: 85.3096, country: 'India', timezone: 5.5),
    CityModel(name: 'Howrah', lat: 22.5769, lon: 88.3186, country: 'India', timezone: 5.5),
    CityModel(name: 'Coimbatore', lat: 11.0168, lon: 76.9558, country: 'India', timezone: 5.5),
    CityModel(name: 'Jabalpur', lat: 23.1815, lon: 79.9864, country: 'India', timezone: 5.5),
    CityModel(name: 'Gwalior', lat: 26.2183, lon: 78.1828, country: 'India', timezone: 5.5),
    CityModel(name: 'Vijayawada', lat: 16.5062, lon: 80.6480, country: 'India', timezone: 5.5),
    CityModel(name: 'Jodhpur', lat: 26.2389, lon: 73.0243, country: 'India', timezone: 5.5),
    CityModel(name: 'Madurai', lat: 9.9252, lon: 78.1198, country: 'India', timezone: 5.5),
    CityModel(name: 'Raipur', lat: 21.2514, lon: 81.6296, country: 'India', timezone: 5.5),
    CityModel(name: 'Chandigarh', lat: 30.7333, lon: 76.7794, country: 'India', timezone: 5.5),
    CityModel(name: 'Guwahati', lat: 26.1445, lon: 91.7362, country: 'India', timezone: 5.5),
    CityModel(name: 'Solapur', lat: 17.6599, lon: 75.9064, country: 'India', timezone: 5.5),
    CityModel(name: 'Hubli-Dharwad', lat: 15.3647, lon: 75.1240, country: 'India', timezone: 5.5),
    CityModel(name: 'Mysore', lat: 12.2958, lon: 76.6394, country: 'India', timezone: 5.5),
    CityModel(name: 'Tiruchirappalli', lat: 10.7905, lon: 78.7047, country: 'India', timezone: 5.5),
    CityModel(name: 'Bareilly', lat: 28.3670, lon: 79.4304, country: 'India', timezone: 5.5),
    CityModel(name: 'Aligarh', lat: 27.8974, lon: 78.0880, country: 'India', timezone: 5.5),
    CityModel(name: 'Tiruppur', lat: 11.1085, lon: 77.3411, country: 'India', timezone: 5.5),
    CityModel(name: 'Gurgaon', lat: 28.4595, lon: 77.0266, country: 'India', timezone: 5.5),
    CityModel(name: 'Moradabad', lat: 28.8351, lon: 78.7733, country: 'India', timezone: 5.5),
    CityModel(name: 'Jalandhar', lat: 31.3260, lon: 75.5762, country: 'India', timezone: 5.5),
  ];

  static List<CityModel> searchCities(String query) {
    if (query.isEmpty) return [];
    return _cities
        .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
