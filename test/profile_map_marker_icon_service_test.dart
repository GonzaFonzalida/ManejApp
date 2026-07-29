import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manejapp/services/profile_map_marker_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('descriptorForProfile devuelve BitmapDescriptor y reutiliza caché',
      () async {
    ProfileMapMarkerIconService.instance.clearCache();
    const dpr = 2.0;

    final a = await ProfileMapMarkerIconService.instance.descriptorForProfile(
      devicePixelRatio: dpr,
      imageUrl: null,
      fallbackLabel: 'Z',
    );
    final b = await ProfileMapMarkerIconService.instance.descriptorForProfile(
      devicePixelRatio: dpr,
      imageUrl: null,
      fallbackLabel: 'Z',
    );

    expect(a, isA<BitmapDescriptor>());
    expect(b, isA<BitmapDescriptor>());
    expect(identical(a, b), isTrue);
    final pin =
        ProfileMapMarkerIconService.anchorFor(ProfileMapMarkerAnchorMode.pin);
    expect(pin.dx, 0.5);
    expect(pin.dy, greaterThan(0.5));
    expect(pin.dy, lessThanOrEqualTo(1.0));
    final geo = ProfileMapMarkerIconService.anchorFor(
        ProfileMapMarkerAnchorMode.geographicCenter);
    expect(geo.dx, closeTo(0.5, 0.02));
  });
}
