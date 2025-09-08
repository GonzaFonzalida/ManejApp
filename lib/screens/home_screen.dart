import 'package:flutter/material.dart';
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
  // Lista original de instructores obtenida de la API
  List<Instructor> _instructors = [];
  // Lista que se mostrará en pantalla, filtrada por la búsqueda
  List<Instructor> _filteredInstructors = [];
  bool _isLoading = true;
  int _selectedIndex = 1;
  // Controlador para el campo de texto de búsqueda
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    // Añade un listener al controlador de texto para filtrar en tiempo real
    _searchController.addListener(_filterInstructors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final data = await ApiService.getInstructors();
      setState(() {
        _instructors = data.map((e) => Instructor.fromJson(e)).toList();
        // Inicializa la lista filtrada con todos los instructores
        _filteredInstructors = _instructors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading instructors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterInstructors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // Si el buscador está vacío, muestra todos los instructores
        _filteredInstructors = _instructors;
      } else {
        // Filtra los instructores que coincidan con el nombre o apellido
        _filteredInstructors = _instructors.where((instructor) {
          final fullName =
              '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
                  .toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
    });
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                    items: _locations.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.black54),
                            const SizedBox(width: 8.0),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLocation = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 150.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey.shade200,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const <Widget>[
                  Text('Mapa Placeholder', style: TextStyle(color: Colors.grey)),
                  Positioned(
                    left: 50,
                    top: 30,
                    child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087)),
                  ),
                  Positioned(
                    right: 60,
                    top: 80,
                    child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087)),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087)),
                  ),
                ],
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
                          backgroundImage: instructor.image != null && instructor.image!.startsWith('http')
                              ? NetworkImage(instructor.image!) as ImageProvider
                              : const AssetImage('assets/default_profile.png'),
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