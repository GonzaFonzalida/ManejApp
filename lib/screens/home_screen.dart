import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/navigation/explore_intent.dart';
import 'package:manejapp/screens/instructor_profile_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/services/location_autocomplete_controller.dart';
import 'package:manejapp/services/profile_map_marker_icon_service.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/app_formatters.dart';
import 'package:manejapp/widgets/design/app_avatar.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/premium_async_states.dart';
import 'package:manejapp/widgets/location_autocomplete_dropdown.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

const _storage = appSecureStorage;

/// Exploración map-first de instructores. Ver [ExploreIntent] en `settings.arguments`.
class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _defaultCenter = LatLng(-34.6037, -58.3816);
  static const double _zoneRadiusKm = 28;
  static const double _nearMeMaxKm = 150;

  List<Instructor> _instructors = [];
  List<Instructor> _filteredInstructors = [];
  final Map<String, LatLng> _instructorLocations = {};

  bool _isLoading = true;
  String? _instructorsLoadError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _zoneFieldController = TextEditingController();
  final FocusNode _zoneFocusNode = FocusNode();

  late final LocationAutocompleteController _zoneAutocomplete;

  GoogleMapController? _mapController;
  LatLng _userLatLng = _defaultCenter;
  LatLng _searchCenterLatLng = _defaultCenter;
  bool _isZoneSearchActive = false;

  String? _filterTransmission;
  bool _filterHasAvailability = false;

  Set<Marker> _homeMarkers = {};
  int _homeMarkersGen = 0;
  Timer? _markersDebounce;

  String? _studentMapImageUrl;
  String _studentMapInitial = 'U';

  bool _routeArgsApplied = false;

  /// `zone` | `filters` | `none`
  String _emptyReason = 'none';

  @override
  void initState() {
    super.initState();
    _zoneAutocomplete = LocationAutocompleteController();
    unawaited(_loadStudentMapMeta());
    _nameController.addListener(_onNameFilterChanged);
    _zoneAutocomplete.addListener(_onZoneAutocompleteChanged);
  }

  void _onZoneAutocompleteChanged() {
    if (mounted) setState(() {});
  }

  void _onNameFilterChanged() {
    _markersDebounce?.cancel();
    _markersDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _recomputeDisplayList();
      unawaited(_rebuildHomeMapMarkers());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;

    final intent = ExploreIntent.fromArguments(
      ModalRoute.of(context)?.settings.arguments,
    );
    if (intent != null) {
      _filterTransmission = intent.transmission;
      _filterHasAvailability = intent.availableToday;
      final q = intent.initialInstructorNameQuery;
      if (q != null && q.isNotEmpty) {
        _nameController.text = q;
      }
      if (!intent.preferUserAnchor) {
        _isZoneSearchActive = false;
        _searchCenterLatLng = _defaultCenter;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (intent.focusZoneSearch) {
          _zoneFocusNode.requestFocus();
        }
      });
    }

    unawaited(_loadInstructors());
    unawaited(_bootstrapLocation(intent?.preferUserAnchor ?? true));
  }

  Future<void> _bootstrapLocation(bool preferUser) async {
    await _getCurrentLocation(silent: true);
    if (!mounted) return;
    if (preferUser && !_isZoneSearchActive) {
      setState(() => _searchCenterLatLng = _userLatLng);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLatLng, 13.2),
      );
    }
    _recomputeDisplayList();
    unawaited(_rebuildHomeMapMarkers());
  }

  @override
  void dispose() {
    _markersDebounce?.cancel();
    _nameController.removeListener(_onNameFilterChanged);
    _zoneAutocomplete.removeListener(_onZoneAutocompleteChanged);
    _zoneAutocomplete.dispose();
    _nameController.dispose();
    _zoneFieldController.dispose();
    _zoneFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadStudentMapMeta() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return;
      final p = await ApiService.getUserProfile(userId);
      final url =
          p['profileImageUrl'] as String? ?? p['profileImage'] as String?;
      final n = p['name'] as String?;
      var initial = 'U';
      if (n != null && n.trim().isNotEmpty) {
        initial = String.fromCharCode(n.trim().runes.first).toUpperCase();
      }
      if (mounted) {
        setState(() {
          _studentMapImageUrl = url;
          _studentMapInitial = initial;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInstructors() async {
    setState(() {
      _isLoading = true;
      _instructorsLoadError = null;
    });
    try {
      final data = await ApiService.getInstructors(
        transmission: _filterTransmission,
        hasAvailability: _filterHasAvailability,
      );
      final instructors = data.map((e) => Instructor.fromJson(e)).toList();

      _instructorLocations.clear();
      for (final instructor in instructors) {
        final location = instructor.user?.location;
        if (location != null && location.isNotEmpty) {
          try {
            final coords = await _geocodeAddress(location);
            if (coords != null) {
              _instructorLocations[instructor.id.toString()] = coords;
            }
          } catch (e) {
            debugPrint('Error geocodificando $location: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _instructors = instructors;
          _isLoading = false;
          _instructorsLoadError = null;
        });
        unawaited(_loadStudentMapMeta());
        _recomputeDisplayList();
        unawaited(_rebuildHomeMapMarkers());
      }
    } catch (e) {
      debugPrint('Error loading instructors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _instructorsLoadError = humanizeApiError(e);
        });
      }
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': '$address, Argentina',
          'format': 'jsonv2',
          'limit': '1',
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
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('Error geocodificando: $e');
    }
    return null;
  }

  void _recomputeDisplayList() {
    final nameQ = _nameController.text.toLowerCase().trim();

    Iterable<Instructor> iter = _instructors;
    if (nameQ.isNotEmpty) {
      iter = iter.where((instructor) {
        final fullName =
            '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
                .toLowerCase();
        return fullName.contains(nameQ);
      });
    }

    final withCoords = <({Instructor i, double km})>[];
    final withoutCoords = <Instructor>[];

    for (final instructor in iter) {
      final loc = _instructorLocations[instructor.id.toString()];
      if (loc == null) {
        withoutCoords.add(instructor);
        continue;
      }
      final d = _distanceKm(
        _searchCenterLatLng.latitude,
        _searchCenterLatLng.longitude,
        loc.latitude,
        loc.longitude,
      );
      if (_isZoneSearchActive) {
        if (d <= _zoneRadiusKm) {
          withCoords.add((i: instructor, km: d));
        }
      } else if (d <= _nearMeMaxKm) {
        withCoords.add((i: instructor, km: d));
      }
    }

    withCoords.sort((a, b) => a.km.compareTo(b.km));

    final List<Instructor> next;
    if (_isZoneSearchActive) {
      next = withCoords.map((e) => e.i).toList();
    } else {
      next = [
        ...withCoords.map((e) => e.i),
        ...withoutCoords,
      ];
    }

    String emptyReason = 'none';
    if (next.isEmpty) {
      if (_instructors.isEmpty) {
        emptyReason = 'none';
      } else if (_isZoneSearchActive) {
        emptyReason = 'zone';
      } else {
        emptyReason = 'filters';
      }
    }

    setState(() {
      _filteredInstructors = next;
      _emptyReason = emptyReason;
    });
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degToRad(double d) => d * math.pi / 180;

  Future<void> _getCurrentLocation({bool silent = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          AppFeedback.showInfo(
            context,
            'Activá la ubicación para ver instructores cerca tuyo.',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            AppFeedback.showInfo(
              context,
              'Necesitamos tu permiso para mostrar instructores cercanos.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          AppFeedback.showInfo(
            context,
            'Ubicación bloqueada. Podés activarla en Ajustes o buscar una zona arriba.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLatLng = LatLng(position.latitude, position.longitude);
        if (!_isZoneSearchActive) {
          _searchCenterLatLng = _userLatLng;
        }
      });
      if (!_isZoneSearchActive) {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userLatLng, 13.2),
        );
      }
      _recomputeDisplayList();
      unawaited(_rebuildHomeMapMarkers());
    } catch (e) {
      if (!silent && mounted) {
        AppFeedback.showError(
          context,
          'No pudimos obtener tu ubicación. Intentá de nuevo.',
        );
      }
    }
  }

  Future<void> _rebuildHomeMapMarkers() async {
    if (!mounted) return;
    final gen = ++_homeMarkersGen;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final userIcon =
        await ProfileMapMarkerIconService.instance.descriptorForProfile(
      devicePixelRatio: dpr,
      imageUrl: _studentMapImageUrl,
      fallbackLabel: _studentMapInitial,
      fallbackColor: AppColors.primary,
    );

    final visibleIds = _filteredInstructors.map((i) => i.id.toString()).toSet();
    final futures = <Future<Marker>>[];

    for (final entry in _instructorLocations.entries) {
      if (!visibleIds.contains(entry.key)) continue;
      final idStr = entry.key;
      final candidates =
          _instructors.where((i) => i.id.toString() == idStr).toList();
      if (candidates.isEmpty) continue;
      final instructor = candidates.first;
      final url =
          instructor.user?.profileImageUrl ?? instructor.user?.profileImage;
      final name = instructor.user?.name ?? '';
      final initial = name.trim().isNotEmpty
          ? String.fromCharCode(name.trim().runes.first).toUpperCase()
          : 'I';
      futures.add(() async {
        final icon =
            await ProfileMapMarkerIconService.instance.descriptorForProfile(
          devicePixelRatio: dpr,
          imageUrl: url,
          fallbackLabel: initial,
          fallbackColor: AppColors.secondary,
        );
        return Marker(
          markerId: MarkerId('instructor_$idStr'),
          position: entry.value,
          icon: icon,
          anchor: ProfileMapMarkerIconService.anchorFor(
              ProfileMapMarkerAnchorMode.pin),
          zIndexInt: 1,
        );
      }());
    }

    final instructorMarkers = await Future.wait(futures);
    if (!mounted || gen != _homeMarkersGen) return;

    final userMarker = Marker(
      markerId: const MarkerId('user'),
      position: _userLatLng,
      icon: userIcon,
      anchor:
          ProfileMapMarkerIconService.anchorFor(ProfileMapMarkerAnchorMode.pin),
      zIndexInt: 2,
    );

    setState(() {
      _homeMarkers = {userMarker, ...instructorMarkers};
    });
  }

  void _applyNearMeFromExplore() {
    setState(() {
      _isZoneSearchActive = false;
      _zoneFieldController.clear();
      _zoneAutocomplete.closeSuggestions();
      _searchCenterLatLng = _userLatLng;
    });
    _recomputeDisplayList();
    unawaited(_rebuildHomeMapMarkers());
    unawaited(
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLatLng, 13.2),
      ),
    );
    unawaited(_getCurrentLocation(silent: true));
  }

  void _onZoneSuggestionSelected(Map<String, String> item) {
    final lat = double.tryParse(item['lat'] ?? '');
    final lon = double.tryParse(item['lon'] ?? '');
    if (lat == null || lon == null) return;

    _zoneAutocomplete.selectSuggestion();
    FocusScope.of(context).unfocus();
    setState(() {
      _isZoneSearchActive = true;
      _searchCenterLatLng = LatLng(lat, lon);
      _zoneFieldController.text = item['display'] ?? '';
    });
    _recomputeDisplayList();
    unawaited(_rebuildHomeMapMarkers());
    unawaited(
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_searchCenterLatLng, 12.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    if (_instructorsLoadError != null && _instructors.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: canGoBack,
          leading: canGoBack
              ? IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(
            'Explorar instructores',
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppErrorState(
              title: 'No pudimos cargar instructores',
              message: _instructorsLoadError,
              onRetry: _loadInstructors,
              retryLabel: 'Reintentar',
            ),
          ),
        ),
      );
    }

    final mapTarget = _isZoneSearchActive ? _searchCenterLatLng : _userLatLng;
    final sheetSizes = ResponsiveLayout.exploreSheetSizes(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: canGoBack,
        leading: canGoBack
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          'Explorar instructores',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: mapTarget,
                zoom: _isZoneSearchActive ? 12.4 : 13.2,
              ),
              onMapCreated: (c) {
                _mapController = c;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  c.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      mapTarget,
                      _isZoneSearchActive ? 12.4 : 13.2,
                    ),
                  );
                });
              },
              markers: _homeMarkers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: sheetSizes.initial,
            minChildSize: sheetSizes.min,
            maxChildSize: sheetSizes.max,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadInstructors,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 6),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildSheetHeader(context)),
                      if (_isLoading && _instructors.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cargando instructores…',
                                  style: AppTextStyles.bodyNormal.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const HomeInstructorResultsSkeleton(
                                    itemCount: 4),
                              ],
                            ),
                          ),
                        )
                      else if (_isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: LinearProgressIndicator(
                              color: AppColors.primary,
                              backgroundColor: AppColors.surfaceLighter,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      if (!_isLoading || _instructors.isNotEmpty)
                        if (_filteredInstructors.isEmpty &&
                            _instructors.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: AppEmptyState(
                                icon: Icons.groups_outlined,
                                title: 'No hay instructores por ahora',
                                subtitle:
                                    'Volvé más tarde o probá sin filtros.',
                                actionLabel: 'Actualizar',
                                onAction: _loadInstructors,
                              ),
                            ),
                          )
                        else if (_filteredInstructors.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _buildEmptyState(),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildPremiumInstructorCard(
                                  _filteredInstructors[index],
                                ),
                                childCount: _filteredInstructors.length,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'explore_my_location',
              onPressed: () => _getCurrentLocation(silent: false),
              backgroundColor: AppColors.surfaceLight,
              child:
                  const Icon(Icons.my_location, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final zone = _emptyReason == 'zone';
    return AppEmptyState(
      icon: zone ? Icons.location_off_rounded : Icons.search_off_rounded,
      title: zone
          ? 'No encontramos instructores en esta zona'
          : 'No encontramos instructores con esos filtros',
      subtitle: zone
          ? 'Probá ampliar la zona o volver a instructores cerca tuyo.'
          : 'Probá ampliar la zona o cambiar el tipo de transmisión.',
      actionLabel: zone ? 'Cerca mío' : 'Limpiar filtros',
      onAction: zone ? _applyNearMeFromExplore : _resetLocalFilters,
    );
  }

  void _resetLocalFilters() {
    setState(() {
      _nameController.clear();
      _filterTransmission = null;
      _filterHasAvailability = false;
    });
    unawaited(_loadInstructors());
  }

  Widget _buildSheetHeader(BuildContext context) {
    final zoneLine = _isZoneSearchActive && _zoneFieldController.text.isNotEmpty
        ? _zoneFieldController.text
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zoneLine != null ? 'Zona: $zoneLine' : 'Cerca de tu ubicación',
            style: AppTextStyles.bodyNormal.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _zoneFieldController,
            focusNode: _zoneFocusNode,
            style:
                AppTextStyles.bodyNormal.copyWith(color: AppColors.textPrimary),
            onChanged: _zoneAutocomplete.onQueryChanged,
            onTap: _zoneAutocomplete.onFocus,
            decoration: InputDecoration(
              hintText: 'Buscar localidad o barrio…',
              hintStyle: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceLighter,
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          ListenableBuilder(
            listenable: _zoneAutocomplete,
            builder: (context, _) {
              if (!_zoneAutocomplete.showSuggestions) {
                return const SizedBox.shrink();
              }
              return LocationAutocompleteDropdown(
                isLoading: _zoneAutocomplete.isLoading,
                error: _zoneAutocomplete.error,
                suggestions: _zoneAutocomplete.suggestions,
                hasQuery: _zoneAutocomplete.hasQuery,
                onSelect: _onZoneSuggestionSelected,
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style:
                AppTextStyles.bodyNormal.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre de instructor',
              hintStyle: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceLighter,
              prefixIcon: const Icon(Icons.person_search_rounded,
                  color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Cerca mío',
                  !_isZoneSearchActive,
                  _applyNearMeFromExplore,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Automático',
                  _filterTransmission == 'AUTOMATIC',
                  () {
                    setState(() {
                      if (_filterTransmission == 'AUTOMATIC') {
                        _filterTransmission = null;
                      } else {
                        _filterTransmission = 'AUTOMATIC';
                      }
                    });
                    unawaited(_loadInstructors());
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Manual',
                  _filterTransmission == 'MANUAL',
                  () {
                    setState(() {
                      if (_filterTransmission == 'MANUAL') {
                        _filterTransmission = null;
                      } else {
                        _filterTransmission = 'MANUAL';
                      }
                    });
                    unawaited(_loadInstructors());
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Disponible hoy',
                  _filterHasAvailability,
                  () {
                    setState(() {
                      _filterHasAvailability = !_filterHasAvailability;
                    });
                    unawaited(_loadInstructors());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resultados (${_filteredInstructors.length})',
            style: AppTextStyles.bodyNormal.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInstructorCard(Instructor instructor) {
    final formattedPrice = AppFormatters.ars(instructor.effectiveHourlyRate);
    final instructorName =
        '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
            .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final location = _instructorLocations[instructor.id.toString()];
            Navigator.pushNamed(
              context,
              InstructorProfileScreen.routeName,
              arguments: {'instructor': instructor, 'location': location},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AppAvatar(
                          diameter: 64,
                          name: instructorName.isEmpty
                              ? 'Instructor'
                              : instructorName,
                          imageUrl: instructor.user?.profileImageUrl ??
                              instructor.user?.profileImage,
                          showBorder: true,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: AppColors.surfaceLight,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.verified,
                                size: 16, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructorName.isEmpty
                                ? 'Instructor'
                                : instructorName,
                            style: AppTextStyles.heading.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                instructor.rating?.toStringAsFixed(1) ?? 'New',
                                style: AppTextStyles.bodyNormal.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' (24 reseñas)',
                                style: AppTextStyles.bodyNormal
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instructor.user?.location ?? 'Zona no especificada',
                            style:
                                AppTextStyles.bodyNormal.copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Desde',
                            style: AppTextStyles.bodyNormal
                                .copyWith(fontSize: 12)),
                        Text(
                          formattedPrice,
                          style: AppTextStyles.heading
                              .copyWith(fontSize: 18, color: AppColors.primary),
                        ),
                        Text('/hora',
                            style: AppTextStyles.bodyNormal
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(
                      'Manual',
                      AppColors.info.withValues(alpha: 0.16),
                      AppColors.info,
                    ),
                    if (instructor.cars?.isNotEmpty == true)
                      _buildTag(
                        'Vehículo incluido',
                        AppColors.secondary.withValues(alpha: 0.16),
                        AppColors.secondary,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final location =
                          _instructorLocations[instructor.id.toString()];
                      Navigator.pushNamed(
                        context,
                        InstructorProfileScreen.routeName,
                        arguments: {
                          'instructor': instructor,
                          'location': location
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLighter,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Ver disponibilidad',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtro $label',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppDurations.fast),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLighter,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
