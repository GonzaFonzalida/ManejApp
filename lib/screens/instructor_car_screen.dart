import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InstructorCarScreen extends StatefulWidget {
  static const routeName = '/instructor_car';
  const InstructorCarScreen({super.key});

  @override
  State<InstructorCarScreen> createState() => _InstructorCarScreenState();
}

class _InstructorCarScreenState extends State<InstructorCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  
  Map<String, dynamic>? _currentCar;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadCar() async {
    try {
      final cars = await ApiService.getCars();
      if (cars.isNotEmpty && mounted) {
        final car = cars.first;
        setState(() {
          _currentCar = car;
          _brandController.text = car['brand'] ?? '';
          _modelController.text = car['model'] ?? '';
          _yearController.text = car['year']?.toString() ?? '';
          _plateController.text = car['plate'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error cargando auto: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final carData = {
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'plate': _plateController.text.trim().toUpperCase(),
      };

      if (_currentCar == null) {
        await ApiService.createCar(carData);
      } else {
        await ApiService.updateCar(_currentCar!['id'].toString(), carData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Auto guardado exitosamente')),
        );
        setState(() => _isEditing = false);
        _loadCar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCar() async {
    if (_currentCar == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Auto'),
        content: const Text('¿Estás seguro de eliminar este auto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteCar(_currentCar!['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Auto eliminado')),
          );
          setState(() {
            _currentCar = null;
            _brandController.clear();
            _modelController.clear();
            _yearController.clear();
            _plateController.clear();
            _isEditing = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Auto'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        actions: [
          if (_currentCar != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_currentCar != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCar,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentCar == null || _isEditing) ...[
                      const Text(
                        'Información del Auto',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _brandController,
                        enabled: _currentCar == null || _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          hintText: 'Ej: Toyota',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la marca';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        enabled: _currentCar == null || _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          hintText: 'Ej: Corolla',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.car_rental),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el modelo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        enabled: _currentCar == null || _isEditing,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          hintText: 'Ej: 2020',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el año';
                          }
                          final year = int.tryParse(value);
                          if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                            return 'Año inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _plateController,
                        enabled: _currentCar == null || _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Patente',
                          hintText: 'Ej: ABC123',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la patente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (_isEditing && _currentCar != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _loadCar();
                                },
                                child: const Text('Cancelar'),
                              ),
                            ),
                          if (_isEditing && _currentCar != null)
                            const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveCar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003087),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(_currentCar == null ? 'Agregar Auto' : 'Guardar Cambios'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_car, size: 48, color: Colors.blue.shade600),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_currentCar!['brand']} ${_currentCar!['model']}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Año ${_currentCar!['year']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              _buildInfoRow(Icons.pin, 'Patente', _currentCar!['plate']),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
