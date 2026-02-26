import 'package:flutter_test/flutter_test.dart';
import 'package:smartgrab/main.dart';

void main() {
  test('OfferLog fromMap handles missing fields', () {
    final log = OfferLog.fromMap('id', {
      'app': 'DoorDash',
      'pay': 9.5,
      'distanceKm': 3.2,
      'shouldAccept': true,
    });

    expect(log.app, 'DoorDash');
    expect(log.pay, 9.5);
    expect(log.distanceKm, 3.2);
    expect(log.shouldAccept, true);
  });
}
