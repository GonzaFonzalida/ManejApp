import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manejapp/services/location_autocomplete_controller.dart';
import '../config/design_system.dart';
import 'location_autocomplete_dropdown.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialCenter;
  final Function(LatLng location, String? address) onLocationChanged;

  const LocationPicker({
    super.key,
    this.initialCenter,
    required this.onLocationChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  late LatLng _currentCenter;
  String? _currentAddress;
  final _locationAutocomplete = LocationAutocompleteController();
  bool _programmaticCameraMove = false;
  LatLng? _lastCameraTarget;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter ?? const LatLng(-34.6037, -58.3816);
    WidgetsBinding.instance.addPostFrameCallback((_) => _determinePosition());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationAutocomplete.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _moveTo(LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void _moveTo(LatLng dest) {
    if (!mounted) return;
    setState(() => _currentCenter = dest);
    _programmaticCameraMove = true;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(dest, 15));
    _updateLocation(dest);
  }

  void _selectSuggestion(Map<String, String> suggestion) {
    try {
      final lat = double.parse(suggestion['lat']!);
      final lon = double.parse(suggestion['lon']!);
      final dest = LatLng(lat, lon);

      _searchController.text = suggestion['display']!;
      _locationAutocomplete.selectSuggestion();

      _moveTo(dest);
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      debugPrint('Error seleccionando ubicación: $e');
    }
  }

  void _onCameraIdle() {
    if (_programmaticCameraMove) {
      _programmaticCameraMove = false;
      return;
    }
    final target = _lastCameraTarget;
    if (target != null && mounted) {
      setState(() => _currentCenter = target);
      _updateLocation(target);
    }
  }

  Future<void> _updateLocation(LatLng point) async {
    widget.onLocationChanged(point, _currentAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (cp) => _lastCameraTarget = cp.target,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 50,
              shadows: [
                Shadow(
                    offset: Offset(0, 2), blurRadius: 4, color: Colors.black26)
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _determinePosition,
            backgroundColor: AppColors.surfaceLight,
            child: const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar dirección (ej. Av. Corrientes)',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _locationAutocomplete.isLoading
                        ? const SizedBox(
                            width: 48,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  onTap: _locationAutocomplete.onFocus,
                  onChanged: _locationAutocomplete.onQueryChanged,
                ),
              ),
              AnimatedBuilder(
                animation: _locationAutocomplete,
                builder: (context, _) {
                  if (!_locationAutocomplete.showSuggestions) {
                    return const SizedBox.shrink();
                  }
                  return LocationAutocompleteDropdown(
                    isLoading: _locationAutocomplete.isLoading,
                    error: _locationAutocomplete.error,
                    suggestions: _locationAutocomplete.suggestions,
                    hasQuery: _locationAutocomplete.hasQuery,
                    onSelect: _selectSuggestion,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
