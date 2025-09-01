import 'package:flutter/material.dart';
import 'package:manejapp/screens/ReservarClase_Screen.dart';
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/models/instructor.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Instructor> _instructors = [];
  bool _isLoading = true;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    try {
      final data = await ApiService.getInstructors();
      print('Instructors data: $data');
      setState(() {
        _instructors = data.map((e) => Instructor.fromJson(e)).toList();
        print('Parsed instructors: $_instructors');
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading instructors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // 👉 Al tocar "Profile", redirige a EditarPerfilScreen
      Navigator.pushNamed(context, ProfileScreen.routeName);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
      body: SingleChildScrollView(
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
                child: InkWell(
                  onTap: () {
                    // TODO: Implementar selección de ubicación
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.location_on_outlined, color: Colors.black54),
                        SizedBox(width: 8.0),
                        Text('Tortuguitas',
                            style: TextStyle(fontSize: 16.0)),
                        SizedBox(width: 8.0),
                        Icon(Icons.arrow_forward_ios,
                            size: 16.0, color: Colors.black54),
                      ],
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
                  children: <Widget>[
                    const Text('Mapa Placeholder',
                        style: TextStyle(color: Colors.grey)),
                    Positioned(
                        left: 50,
                        top: 30,
                        child: Icon(Icons.directions_car,
                            size: 30, color: Color(0xFF003087))),
                    Positioned(
                        right: 60,
                        top: 80,
                        child: Icon(Icons.directions_car,
                            size: 30, color: Color(0xFF003087))),
                    Positioned(
                        bottom: 20,
                        child: Icon(Icons.directions_car,
                            size: 30, color: Color(0xFF003087))),
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
                child: const TextField(
                  decoration: InputDecoration(
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
              else if (_instructors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No hay instructores disponibles en esta área.',
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
                  itemCount: _instructors.length,
                  itemBuilder: (context, index) {
                    final instructor = _instructors.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 30.0,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: AssetImage(instructor.image),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  instructor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16.0),
                                    const SizedBox(width: 4.0),
                                    Text('${instructor.rating} ★',
                                        style:
                                            const TextStyle(fontSize: 14.0)),
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
                                arguments: _instructors[index], // 👉 pasa el instructor
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF003087),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

