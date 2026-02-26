import 'package:flutter_test/flutter_test.dart';
import 'package:smartgrab/main.dart';

void main() {
  test('OfferLog fromMap handles missing fields', () {
    final log = OfferLog.fromMap('id', {
      'app': 'DoorDash',
      'pay': 9.5,
      'distanceKm': 3.2,
      'shouldAccept': true,
      'lat': 47.61,
      'lng': -122.33,
    });

    expect(log.app, 'DoorDash');
    expect(log.pay, 9.5);
    expect(log.distanceKm, 3.2);
    expect(log.shouldAccept, true);
    expect(log.lat, 47.61);
    expect(log.lng, -122.33);
  });
}
