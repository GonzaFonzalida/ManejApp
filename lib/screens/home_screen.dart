import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  // Define the constant route name for navigation
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy data for instructors (will be fetched dynamically later)
  // To simulate no data, you can uncomment the line below and comment out the list.
  // final List<Instructor> _instructors = [];
  final List<Instructor> _instructors = [
    Instructor(
      name: 'Rodrigo Quesada',
      rating: 4.8,
      experienceYears: 4,
      hourlyRate: 45000,
      image: 'assets/rodrigo.jpg', // Replace with actual asset path
    ),
    Instructor(
      name: 'Somali Gutierrez',
      rating: 4.7,
      experienceYears: 4,
      hourlyRate: 49000,
      image: 'assets/somali.jpg', // Replace with actual asset path
    ),
    Instructor(
      name: 'Rodrigo Quesada',
      rating: 4.9,
      experienceYears: 4,
      hourlyRate: 62000,
      image: 'assets/rodrigo2.jpg', // Replace with actual asset path
    ),
  ];

  int _selectedIndex = 0; // Index for the bottom navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // You can add navigation logic here for other tabs
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This line removes the back button from the AppBar
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
                    // TODO: Implement location selection
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        Text('Tortuguitas', style: TextStyle(fontSize: 16.0)),
                        SizedBox(width: 8.0),
                        Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.black54),
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
                    const Text('Mapa Placeholder', style: TextStyle(color: Colors.grey)),
                    Positioned(left: 50, top: 30, child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087))),
                    Positioned(right: 60, top: 80, child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087))),
                    Positioned(bottom: 20, child: Icon(Icons.directions_car, size: 30, color: Color(0xFF003087))),
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
              if (_instructors.isEmpty)
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
                                    Icon(Icons.star, color: Colors.amber, size: 16.0),
                                    const SizedBox(width: 4.0),
                                    Text('${instructor.rating} ★', style: const TextStyle(fontSize: 14.0)),
                                    const SizedBox(width: 8.0),
                                    Text('${instructor.experienceYears} años de experiencia', style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${instructor.hourlyRate}/h',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Color(0xFF003087),
                            ),
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
        unselectedItemColor: Colors.grey.shade500,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Data model for an instructor
class Instructor {
  final String name;
  final double rating;
  final int experienceYears;
  final int hourlyRate;
  final String image;

  Instructor({
    required this.name,
    required this.rating,
    required this.experienceYears,
    required this.hourlyRate,
    required this.image,
  });
}