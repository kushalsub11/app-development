import '../models/models.dart';

class CityModel {
  final String name;
  final double lat;
  final double lon;
  final String country;

  CityModel({
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
  });

  @override
  String toString() => '$name, $country';
}

class LocationService {
  static final List<CityModel> _cities = [
    // Nepal
    CityModel(name: 'Kathmandu', lat: 27.7172, lon: 85.3240, country: 'Nepal'),
    CityModel(name: 'Pokhara', lat: 28.2096, lon: 83.9856, country: 'Nepal'),
    CityModel(name: 'Lalitpur', lat: 27.671, lon: 85.324, country: 'Nepal'),
    CityModel(name: 'Bharatpur', lat: 27.6833, lon: 84.4333, country: 'Nepal'),
    CityModel(name: 'Biratnagar', lat: 26.45, lon: 87.2667, country: 'Nepal'),
    CityModel(name: 'Birgunj', lat: 27.0163, lon: 84.8778, country: 'Nepal'),
    CityModel(name: 'Dharan', lat: 26.8125, lon: 87.2831, country: 'Nepal'),
    CityModel(name: 'Nepalgunj', lat: 28.05, lon: 81.6167, country: 'Nepal'),
    CityModel(name: 'Itahari', lat: 26.6644, lon: 87.2717, country: 'Nepal'),
    CityModel(name: 'Hetauda', lat: 27.4277, lon: 85.0348, country: 'Nepal'),
    CityModel(name: 'Janakpur', lat: 26.7271, lon: 85.9229, country: 'Nepal'),
    CityModel(name: 'Butwal', lat: 27.7006, lon: 83.4484, country: 'Nepal'),
    CityModel(name: 'Tulsipur', lat: 28.1289, lon: 82.2972, country: 'Nepal'),
    CityModel(name: 'Siddharthanagar', lat: 27.502, lon: 83.45, country: 'Nepal'),
    
    // India
    CityModel(name: 'New Delhi', lat: 28.6139, lon: 77.2090, country: 'India'),
    CityModel(name: 'Mumbai', lat: 19.0760, lon: 72.8777, country: 'India'),
    CityModel(name: 'Bangalore', lat: 12.9716, lon: 77.5946, country: 'India'),
    CityModel(name: 'Chennai', lat: 13.0827, lon: 80.2707, country: 'India'),
    CityModel(name: 'Kolkata', lat: 22.5726, lon: 88.3639, country: 'India'),
    CityModel(name: 'Hyderabad', lat: 17.3850, lon: 78.4867, country: 'India'),
    CityModel(name: 'Ahmedabad', lat: 23.0225, lon: 72.5714, country: 'India'),
    CityModel(name: 'Pune', lat: 18.5204, lon: 73.8567, country: 'India'),
    CityModel(name: 'Surat', lat: 21.1702, lon: 72.8311, country: 'India'),
    CityModel(name: 'Jaipur', lat: 26.9124, lon: 75.7873, country: 'India'),
    CityModel(name: 'Lucknow', lat: 26.8467, lon: 80.9462, country: 'India'),
    CityModel(name: 'Kanpur', lat: 26.4499, lon: 80.3319, country: 'India'),
    CityModel(name: 'Nagpur', lat: 21.1458, lon: 79.0882, country: 'India'),
    CityModel(name: 'Indore', lat: 22.7196, lon: 75.8577, country: 'India'),
    CityModel(name: 'Thane', lat: 19.2183, lon: 72.9781, country: 'India'),
    CityModel(name: 'Bhopal', lat: 23.2599, lon: 77.4126, country: 'India'),
    CityModel(name: 'Visakhapatnam', lat: 17.6868, lon: 83.2185, country: 'India'),
    CityModel(name: 'Pimpri-Chinchwad', lat: 18.6298, lon: 73.7997, country: 'India'),
    CityModel(name: 'Patna', lat: 25.5941, lon: 85.1376, country: 'India'),
    CityModel(name: 'Vadodara', lat: 22.3072, lon: 73.1812, country: 'India'),
    CityModel(name: 'Ghaziabad', lat: 28.6692, lon: 77.4538, country: 'India'),
    CityModel(name: 'Ludhiana', lat: 30.9010, lon: 75.8573, country: 'India'),
    CityModel(name: 'Agra', lat: 27.1767, lon: 78.0081, country: 'India'),
    CityModel(name: 'Nashik', lat: 19.9975, lon: 73.7898, country: 'India'),
    CityModel(name: 'Faridabad', lat: 28.4089, lon: 77.3178, country: 'India'),
    CityModel(name: 'Meerut', lat: 28.9845, lon: 77.7064, country: 'India'),
    CityModel(name: 'Rajkot', lat: 22.3039, lon: 70.8022, country: 'India'),
    CityModel(name: 'Varanasi', lat: 25.3176, lon: 83.0062, country: 'India'),
    CityModel(name: 'Srinagar', lat: 34.0837, lon: 74.7973, country: 'India'),
    CityModel(name: 'Aurangabad', lat: 19.8762, lon: 75.3433, country: 'India'),
    CityModel(name: 'Dhanbad', lat: 23.7957, lon: 86.4304, country: 'India'),
    CityModel(name: 'Amritsar', lat: 31.6340, lon: 74.8723, country: 'India'),
    CityModel(name: 'Navi Mumbai', lat: 19.0330, lon: 73.0297, country: 'India'),
    CityModel(name: 'Allahabad', lat: 25.4358, lon: 81.8463, country: 'India'),
    CityModel(name: 'Ranchi', lat: 23.3441, lon: 85.3096, country: 'India'),
    CityModel(name: 'Howrah', lat: 22.5769, lon: 88.3186, country: 'India'),
    CityModel(name: 'Coimbatore', lat: 11.0168, lon: 76.9558, country: 'India'),
    CityModel(name: 'Jabalpur', lat: 23.1815, lon: 79.9864, country: 'India'),
    CityModel(name: 'Gwalior', lat: 26.2183, lon: 78.1828, country: 'India'),
    CityModel(name: 'Vijayawada', lat: 16.5062, lon: 80.6480, country: 'India'),
    CityModel(name: 'Jodhpur', lat: 26.2389, lon: 73.0243, country: 'India'),
    CityModel(name: 'Madurai', lat: 9.9252, lon: 78.1198, country: 'India'),
    CityModel(name: 'Raipur', lat: 21.2514, lon: 81.6296, country: 'India'),
    CityModel(name: 'Chandigarh', lat: 30.7333, lon: 76.7794, country: 'India'),
    CityModel(name: 'Guwahati', lat: 26.1445, lon: 91.7362, country: 'India'),
    CityModel(name: 'Solapur', lat: 17.6599, lon: 75.9064, country: 'India'),
    CityModel(name: 'Hubli-Dharwad', lat: 15.3647, lon: 75.1240, country: 'India'),
    CityModel(name: 'Mysore', lat: 12.2958, lon: 76.6394, country: 'India'),
    CityModel(name: 'Tiruchirappalli', lat: 10.7905, lon: 78.7047, country: 'India'),
    CityModel(name: 'Bareilly', lat: 28.3670, lon: 79.4304, country: 'India'),
    CityModel(name: 'Aligarh', lat: 27.8974, lon: 78.0880, country: 'India'),
    CityModel(name: 'Tiruppur', lat: 11.1085, lon: 77.3411, country: 'India'),
    CityModel(name: 'Gurgaon', lat: 28.4595, lon: 77.0266, country: 'India'),
    CityModel(name: 'Moradabad', lat: 28.8351, lon: 78.7733, country: 'India'),
    CityModel(name: 'Jalandhar', lat: 31.3260, lon: 75.5762, country: 'India'),
  ];

  static List<CityModel> searchCities(String query) {
    if (query.isEmpty) return [];
    return _cities
        .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
