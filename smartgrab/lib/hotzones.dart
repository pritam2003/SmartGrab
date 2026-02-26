import 'dart:math';

class HotzonePoint {
  const HotzonePoint({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class Hotzone {
  const Hotzone({required this.lat, required this.lng, required this.count});

  final double lat;
  final double lng;
  final int count;
}

List<Hotzone> computeHotzones(
  List<HotzonePoint> points, {
  double gridSize = 0.01,
}) {
  if (points.isEmpty) return const [];

  final buckets = <String, _Bucket>{};
  for (final point in points) {
    final bucketLat = (point.lat / gridSize).round() * gridSize;
    final bucketLng = (point.lng / gridSize).round() * gridSize;
    final key = '${bucketLat.toStringAsFixed(5)}|${bucketLng.toStringAsFixed(5)}';
    final bucket = buckets.putIfAbsent(key, () => _Bucket());
    bucket.count += 1;
    bucket.sumLat += point.lat;
    bucket.sumLng += point.lng;
  }

  return buckets.values
      .map((bucket) => Hotzone(
            lat: bucket.sumLat / max(bucket.count, 1),
            lng: bucket.sumLng / max(bucket.count, 1),
            count: bucket.count,
          ))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

class _Bucket {
  int count = 0;
  double sumLat = 0;
  double sumLng = 0;
}
