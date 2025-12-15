import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _students = [];
  List<dynamic> _instructors = [];
  List<dynamic> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final students = await ApiService.getUsersByRole('STUDENT');
      final instructors = await ApiService.getInstructors();
      
      setState(() {
        _students = students;
        _instructors = instructors;
        _allUsers = [...students, ...instructors];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Gestión de Usuarios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF003087),
          tabs: [
            Tab(text: 'Todos (${_allUsers.length})'),
            Tab(text: 'Estudiantes (${_students.length})'),
            Tab(text: 'Instructores (${_instructors.length})'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersList(_allUsers),
                    _buildUsersList(_students),
                    _buildUsersList(_instructors),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<dynamic> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No hay usuarios', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF003087),
                child: Text(
                  ((user['user']?['firstName'] ?? user['firstName'] ?? user['name'] ?? 'U')[0]).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('${user['user']?['firstName'] ?? user['firstName'] ?? user['name'] ?? ''} ${user['user']?['lastName'] ?? user['lastName'] ?? user['surname'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['user']?['email'] ?? user['email'] ?? ''),
                  Text('Rol: ${user['user']?['role'] ?? user['role'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: user['user']?['isActive'] ?? user['isActive'] ?? true,
                    onChanged: (value) => _toggleUserStatus(user, value),
                    activeTrackColor: Colors.green,
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('Ver detalles')),
                    ],
                    onSelected: (value) => _handleUserAction(value, user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(dynamic user, bool isActive) async {
    try {
      final userId = (user['user']?['id'] ?? user['userId'] ?? user['id']).toString();
      debugPrint('Toggling user $userId to ${isActive ? "active" : "inactive"}');
      await ApiService.manageUser(userId, isActive: isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario ${isActive ? "activado" : "desactivado"} exitosamente')),
        );
        _loadUsers();
      }
    } catch (e) {
      debugPrint('Error toggling user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleUserAction(String action, dynamic user) {
    if (action == 'view') {
      _showUserDetails(user);
    }
  }

  void _showUserDetails(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['user']?['firstName'] ?? user['firstName'] ?? user['name'] ?? ''} ${user['user']?['lastName'] ?? user['lastName'] ?? user['surname'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user['user']?['email'] ?? user['email'] ?? 'N/A'),
            _buildDetailRow('DNI', user['user']?['dni'] ?? user['dni'] ?? 'N/A'),
            _buildDetailRow('Rol', user['user']?['role'] ?? user['role'] ?? 'N/A'),
            _buildDetailRow('Fecha de nacimiento', user['user']?['birthDate'] ?? user['birthDate'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }


}
