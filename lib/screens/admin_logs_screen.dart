// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pantalla legacy de admin; fuera del flujo V1 móvil.
@Deprecated('V1: usar panel web. No cargar logs desde la app móvil.')
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  List<dynamic> _logs = [];
  List<dynamic> _stats = [];
  bool _isLoading = true;
  String? _selectedLevel;
  final List<String> _levels = ['error', 'warn', 'info', 'debug'];

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() {
      _logs = [];
      _isLoading = false;
    });
  }

  Future<void> _loadStats() async {
    if (!mounted) setState(() => _stats = []);
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warn':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warn':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'debug':
        return Icons.bug_report;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLogs();
          await _loadStats();
        },
        child: Column(
          children: [
            if (_stats.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estadísticas (últimos 7 días)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stats.map((stat) {
                        final level = stat['level'] as String;
                        final count = stat['count'] as int;
                        return Chip(
                          avatar: Icon(_getLevelIcon(level),
                              size: 16, color: _getLevelColor(level)),
                          label: Text('$level: $count'),
                          backgroundColor:
                              _getLevelColor(level).withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por nivel',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todos')),
                        ..._levels.map((level) =>
                            DropdownMenuItem(value: level, child: Text(level))),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedLevel = value);
                        _loadLogs();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadLogs,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                      ? const Center(child: Text('No hay logs disponibles'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final level = log['level'] as String;
                            final message = log['message'] as String;
                            final timestamp =
                                DateTime.parse(log['timestamp'] as String);
                            final context = log['context'];
                            final error = log['error'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: Icon(_getLevelIcon(level),
                                    color: _getLevelColor(level)),
                                title: Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _getLevelColor(level),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy HH:mm:ss')
                                      .format(timestamp),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (context != null) ...[
                                          const Text('Contexto:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(context.toString(),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          const SizedBox(height: 12),
                                        ],
                                        if (error != null) ...[
                                          const Text('Error:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red)),
                                          const SizedBox(height: 4),
                                          Text(error.toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
