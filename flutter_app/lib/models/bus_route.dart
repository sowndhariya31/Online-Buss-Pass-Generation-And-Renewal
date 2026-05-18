class BusRoute {
  final int id;
  final String routeName;
  final String fromLocation;
  final String toLocation;
  final double price;

  BusRoute({
    required this.id,
    required this.routeName,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'],
      routeName: json['route_name'] ?? '',
      fromLocation: json['from_location'] ?? '',
      toLocation: json['to_location'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}
