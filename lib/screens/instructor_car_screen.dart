import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/confirmation_dialog.dart';
import 'package:manejapp/widgets/design/app_badge.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

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
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  bool _isEditing = false;
  String? _error;

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

  Future<void> _loadCar({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final cars = await ApiService.getCars();
      if (!mounted) return;
      final car = cars.isEmpty ? null : Map<String, dynamic>.from(cars.first);
      setState(() {
        _currentCar = car;
        _loading = false;
        _error = null;
        if (car != null) {
          _fillControllers(car);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = humanizeApiError(error);
      });
    }
  }

  void _fillControllers(Map<String, dynamic> car) {
    _brandController.text = car['brand']?.toString() ?? '';
    _modelController.text = car['model']?.toString() ?? '';
    _yearController.text = car['year']?.toString() ?? '';
    _plateController.text = car['plate']?.toString() ?? '';
  }

  void _startEditing() {
    final car = _currentCar;
    if (car != null) _fillControllers(car);
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    final car = _currentCar;
    if (car != null) _fillControllers(car);
    FocusScope.of(context).unfocus();
    setState(() => _isEditing = false);
  }

  Future<void> _saveCar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);
    try {
      final carData = <String, dynamic>{
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'plate': _plateController.text.trim().toUpperCase(),
      };

      final car = _currentCar;
      if (car == null) {
        await ApiService.createCar(carData);
      } else {
        await ApiService.updateCar(car['id'].toString(), carData);
      }

      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        car == null ? 'Vehículo agregado' : 'Cambios guardados',
      );
      setState(() => _isEditing = false);
      await _loadCar(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteCar() async {
    final car = _currentCar;
    if (car == null || _deleting) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Eliminar vehículo',
      message:
          'Vas a dejar de poder recibir reservas hasta que cargues otro vehículo activo. ¿Querés eliminarlo?',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ApiService.deleteCar(car['id'].toString());
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Vehículo eliminado');
      setState(() {
        _currentCar = null;
        _isEditing = true;
        _clearControllers();
      });
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _clearControllers() {
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
    _plateController.clear();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Ingresá $label';
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresá el año';
    final year = int.tryParse(value.trim());
    final maxYear = DateTime.now().year + 1;
    if (year == null || year < 1900 || year > maxYear) {
      return 'Ingresá un año válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi vehículo'),
        actions: [
          if (_currentCar != null && !_isEditing)
            IconButton(
              tooltip: 'Editar vehículo',
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null && _currentCar == null) {
      return Center(
        child: AppErrorState(
          title: 'No pudimos cargar tu vehículo',
          message: _error,
          onRetry: _loadCar,
        ),
      );
    }

    return ResponsiveScrollBody(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _currentCar == null || _isEditing
          ? _buildVehicleForm()
          : _buildVehicleSummary(),
    );
  }

  Widget _buildVehicleForm() {
    final isNew = _currentCar == null;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isNew
                ? 'Cargá el vehículo de tus clases'
                : 'Editá los datos del vehículo',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estos datos ayudan al alumno a identificar el vehículo y son necesarios para publicar tu perfil.',
            style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                AppInput(
                  label: 'Marca',
                  hint: 'Ej.: Toyota',
                  controller: _brandController,
                  prefixIcon: Icons.directions_car_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _required(value, 'la marca'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'Modelo',
                  hint: 'Ej.: Corolla',
                  controller: _modelController,
                  prefixIcon: Icons.car_rental_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _required(value, 'el modelo'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'Año',
                  hint: 'Ej.: 2022',
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.calendar_today_outlined,
                  validator: _validateYear,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'Patente',
                  hint: 'Ej.: AB123CD',
                  controller: _plateController,
                  prefixIcon: Icons.pin_outlined,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveCar(),
                  validator: (value) => _required(value, 'la patente'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: isNew ? 'Guardar vehículo' : 'Guardar cambios',
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _saveCar,
            isLoading: _saving,
          ),
          if (!isNew) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Cancelar edición',
              type: AppButtonType.outline,
              onPressed: _saving ? null : _cancelEditing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleSummary() {
    final car = _currentCar!;
    final active = car['isActive'] != false;
    final brand = car['brand']?.toString() ?? 'Vehículo';
    final model = car['model']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vehículo de las clases', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Esta es la información que usamos para validar tu operación y orientar a tus alumnos.',
          style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$brand $model'.trim(),
                          style: AppTextStyles.heading.copyWith(fontSize: 21),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        active
                            ? AppBadge.success('Activo',
                                icon: Icons.check_circle_outline_rounded)
                            : AppBadge.warning('Inactivo',
                                icon: Icons.pause_circle_outline_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Año',
                car['year']?.toString() ?? 'Sin informar',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow(
                Icons.pin_outlined,
                'Patente',
                car['plate']?.toString() ?? 'Sin informar',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          text: 'Editar vehículo',
          icon: Icons.edit_outlined,
          onPressed: _startEditing,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          text: 'Eliminar vehículo',
          icon: Icons.delete_outline_rounded,
          type: AppButtonType.ghost,
          onPressed: _deleting ? null : _deleteCar,
          isLoading: _deleting,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: AppSpacing.compact),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
