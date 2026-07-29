// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/profile_map_marker_icon_service.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'dart:convert';

@Deprecated('V1: pantalla legacy fuera del flujo. El mapa vive en HomeScreen.')
class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _addressController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(-34.505, -58.695); // Tortuguitas
  bool _searching = false;
  Set<Marker> _markers = {};
  BitmapDescriptor? _placeIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareMarker());
  }

  Future<void> _prepareMarker() async {
    if (!mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final icon =
        await ProfileMapMarkerIconService.instance.descriptorForProfile(
      devicePixelRatio: dpr,
      imageUrl: null,
      fallbackLabel: '★',
      fallbackColor: AppColors.primary,
    );
    if (!mounted) return;
    setState(() {
      _placeIcon = icon;
      _markers = {
        Marker(
          markerId: const MarkerId('center'),
          position: _center,
          icon: icon,
          anchor: ProfileMapMarkerIconService.anchorFor(
              ProfileMapMarkerAnchorMode.pin),
        ),
      };
    });
  }

  Future<void> _refreshMarkerPosition() async {
    final icon = _placeIcon ??
        await ProfileMapMarkerIconService.instance.descriptorForProfile(
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          imageUrl: null,
          fallbackLabel: '★',
          fallbackColor: AppColors.primary,
        );
    if (!mounted) return;
    setState(() {
      _placeIcon = icon;
      _markers = {
        Marker(
          markerId: const MarkerId('center'),
          position: _center,
          icon: icon,
          anchor: ProfileMapMarkerIconService.anchorFor(
              ProfileMapMarkerAnchorMode.pin),
        ),
      };
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá una dirección')),
      );
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'ar',
        },
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'ManejApp/1.0 (Flutter)'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list[0] as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            final pos = LatLng(lat, lon);
            setState(() {
              _center = pos;
            });
            await _refreshMarkerPosition();
            await _mapController
                ?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No se pudo interpretar la ubicación')),
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró la dirección')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error buscando dirección (HTTP ${res.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('Error geocodificando: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buscando la dirección: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchPadding = ResponsiveLayout.scrollPadding(
      context,
      base: const EdgeInsets.fromLTRB(12, 12, 12, 0),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de ManejApp')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: searchPadding,
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText:
                      'Ingresá la dirección exacta (calle, número, ciudad)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Usar mi ubicación',
                          icon: const Icon(Icons.my_location),
                          onPressed: _searchAddress,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 13,
                ),
                onMapCreated: (c) => _mapController = c,
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
