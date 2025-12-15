import 'package:flutter/material.dart';
import 'package:manejapp/screens/reservar_clase_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Instructor> _instructors = [];
  List<Instructor> _filteredInstructors = [];
  final Map<String, LatLng> _instructorLocations = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(-34.505, -58.695);
  bool _locationLoading = false;
  bool _addressSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    _searchController.addListener(_filterInstructors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final data = await ApiService.getInstructors();
      final instructors = data.map((e) => Instructor.fromJson(e)).toList();
      
      // Geocodificar ubicaciones de instructores
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
          _filteredInstructors = _instructors;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading instructors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  void _filterInstructors() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredInstructors = _instructors;
        } else {
          _filteredInstructors = _instructors.where((instructor) {
            final fullName =
                '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
                    .toLowerCase();
            return fullName.contains(query);
          }).toList();
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación están deshabilitados.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos de ubicación denegados permanentemente.';
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  void _searchNearbyInstructors() {
    // Calcular distancias y ordenar instructores por cercanía
    final instructorsWithDistance = _instructors.where((instructor) {
      return _instructorLocations.containsKey(instructor.id.toString());
    }).map((instructor) {
      final instructorLocation = _instructorLocations[instructor.id.toString()]!;
      final distance = _calculateDistance(
        _currentLocation.latitude,
        _currentLocation.longitude,
        instructorLocation.latitude,
        instructorLocation.longitude,
      );
      return {'instructor': instructor, 'distance': distance};
    }).toList();

    instructorsWithDistance.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double)
    );

    if (mounted) {
      setState(() {
        _filteredInstructors = instructorsWithDistance
          .map((e) => e['instructor'] as Instructor)
          .toList();
      });
    }

    if (_filteredInstructors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron instructores con ubicación registrada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se encontraron ${_filteredInstructors.length} instructores cercanos')),
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  Future<String?> _getInstructorImageUrl(Instructor instructor) async {
    return instructor.user?.profileImageUrl;
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá una dirección')),
      );
      return;
    }
    
    setState(() => _addressSearching = true);
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
            if (mounted) {
              setState(() {
                _currentLocation = pos;
              });
            }
            _mapController.move(pos, 16.0);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo interpretar la ubicación')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se encontró la dirección')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error buscando dirección (HTTP ${res.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error buscando la dirección: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addressSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Instructor'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20.0),
              const Center(
                child: Text(
                  'Encuentra el instructor perfecto para ti',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Ingresá una dirección exacta',
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF003087)),
                          suffixIcon: _locationLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.my_location, color: Color(0xFF003087)),
                                  onPressed: _getCurrentLocation,
                                  tooltip: 'Usar mi ubicación',
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: _addressSearching ? null : _searchAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003087),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: _addressSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          // Marcador de ubicación actual
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: _currentLocation,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          // Marcadores de instructores
                          ..._instructorLocations.entries.map((entry) {
                            return Marker(
                              width: 80.0,
                              height: 80.0,
                              point: entry.value,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.red,
                                size: 40,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _searchNearbyInstructors,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Buscar instructor'),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Filtrar por nombre',
                    prefixIcon: Icon(Icons.filter_list, color: Color(0xFF003087)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16.0),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Instructores cercanos',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12.0),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredInstructors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No se encontraron instructores con ese nombre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredInstructors.length,
                  itemBuilder: (context, index) {
                    final instructor = _filteredInstructors.elementAt(index);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: <Widget>[
                            FutureBuilder<String?>(
                              future: _getInstructorImageUrl(instructor),
                              builder: (context, snapshot) {
                                final imageUrl = snapshot.data;
                                return CircleAvatar(
                                  radius: 35.0,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: imageUrl != null
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null
                                      ? Icon(Icons.person, size: 35, color: Colors.blue.shade600)
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: <Widget>[
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 18.0),
                                      const SizedBox(width: 4.0),
                                      Text('${instructor.rating ?? '5.0'}',
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 12.0),
                                      Icon(Icons.school, color: Colors.grey.shade600, size: 16),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        '${instructor.experienceYears} años',
                                        style: TextStyle(
                                            fontSize: 14.0, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money, color: Colors.green.shade600, size: 16),
                                      Text(
                                        '\$${instructor.user?.hourlyRate?.toStringAsFixed(0) ?? '45.000'}/hora',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  ReservarClaseScreen.routeName,
                                  arguments: instructor,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003087),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Reservar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}