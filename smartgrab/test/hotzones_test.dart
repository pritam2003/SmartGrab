import 'package:flutter_test/flutter_test.dart';
import 'package:smartgrab/hotzones.dart';

void main() {
  test('computeHotzones groups points into buckets', () {
    final points = [
      const HotzonePoint(lat: 47.6101, lng: -122.2015),
      const HotzonePoint(lat: 47.6102, lng: -122.2016),
      const HotzonePoint(lat: 47.6202, lng: -122.3016),
    ];

    final zones = computeHotzones(points, gridSize: 0.01);

    expect(zones.length, 2);
    expect(zones.first.count, 2);
  });
}
