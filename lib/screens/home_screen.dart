import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:manejapp/screens/ReservarClase_Screen.dart';
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/screens/info_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Instructor> _instructors = [];
  List<Instructor> _filteredInstructors = [];
  bool _isLoading = true;
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng _mapCenter = LatLng(-34.4596, -58.7402);
  List<Marker> _mapMarkers = [];
  bool _locationSearching = false;

  final List<String> _locations = [
    'Tortuguitas',
    'Malvinas Argentinas',
    'Grand Bourg',
    'Los Polvorines',
    'Ingeniero Pablo Nogues',
    'Villa de Mayo',
    'Tierras Altas',
    'Ing. Adolfo Sourdeaux',
    'Área de Promoción',
  ];
  String _selectedLocation = 'Tortuguitas';

  // Coordenadas de ejemplo (Tortuguitas, Bs As)
  final LatLng _defaultCenter = LatLng(-34.4596, -58.7402);

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    _searchController.addListener(_filterInstructors);
    _mapCenter = _defaultCenter;
    _mapMarkers = [
      Marker(
        point: _defaultCenter,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_pin,
          color: Color(0xFF003087),
          size: 40,
        ),
      ),
    ];
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
      setState(() {
        _instructors = data.map((e) => Instructor.fromJson(e)).toList();
        _filteredInstructors = _instructors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading instructors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterInstructors() {
    final query = _searchController.text.toLowerCase();
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

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá una dirección')),
      );
      return;
    }
    setState(() => _locationSearching = true);
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
              _mapCenter = pos;
              _mapMarkers = [
                Marker(
                  point: pos,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xFF003087),
                    size: 40,
                  ),
                ),
              ];
            });
            _mapController.move(pos, 15.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo interpretar la ubicación')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró la dirección')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error buscando dirección (HTTP ${res.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('Error geocodificando: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buscando la dirección: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _locationSearching = false);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, ProfileScreen.routeName);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20.0),
            const Center(
              child: Text(
                'ManejApp',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003087),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            const Center(
              child: Text(
                'Conectá con tu próximo instructor',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Ingresá una dirección exacta',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black54),
                    suffixIcon: _locationSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: Colors.black54),
                            onPressed: _searchAddress,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchAddress(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Mapa real con flutter_map
            Container(
              height: 200.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: _mapMarkers,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar instructor',
                  prefixIcon: Icon(Icons.menu, color: Colors.black54),
                  suffixIcon: Icon(Icons.search, color: Colors.black54),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 30.0,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: instructor.image != null &&
                                  instructor.image!.startsWith('http')
                              ? NetworkImage(instructor.image!)
                                  as ImageProvider
                              : const AssetImage('assets/car3.png'),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16.0),
                                  const SizedBox(width: 4.0),
                                  Text('${instructor.rating ?? '0.0'} ★',
                                      style: const TextStyle(fontSize: 14.0)),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    '${instructor.experienceYears} años de experiencia',
                                    style: const TextStyle(
                                        fontSize: 12.0, color: Colors.grey),
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
                          child: const Text('Reservar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent() {
    return const InfoScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(Icons.info_outline, color: Colors.black),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildInfoContent() : _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF003087),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
