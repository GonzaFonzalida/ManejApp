import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/screens/student_home_dashboard_screen.dart';
import 'package:manejapp/screens/student_classes_screen.dart';
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/screens/settings_screen.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/widgets/design/app_bottom_nav.dart';

class StudentDashboardScreen extends StatefulWidget {
  static const routeName = '/student_dashboard';
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialIndex')) {
        setState(() {
          _selectedIndex = args['initialIndex'] as int;
        });
      }
      _initialized = true;
    }
  }

  late final List<Widget> _screens = [
    StudentHomeDashboardScreen(
        onSwitchTab: (i) => setState(() => _selectedIndex = i)),
    const StudentClassesScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        itemKeys: const {1: E2eKeys.studentNavReservations},
      ),
    );
  }
}
